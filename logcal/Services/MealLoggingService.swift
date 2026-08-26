//
//  MealLoggingService.swift
//  logcal
//
//  Meal logging pipeline for Siri and shortcuts.
//

import Foundation
import SwiftData
import UIKit
import WidgetKit

struct LoggedMealResult {
    let entry: MealEntry
    let response: MealLogResponse
}

@MainActor
struct MealLoggingService {
    private let cloudSyncService = CloudSyncService()
    private let appConfigService = AppConfigService()

    func logMeal(
        foodText: String,
        mealType: MealType? = nil,
        selectedDate: Date = Date(),
        images: [UIImage] = [],
        modelContext: ModelContext
    ) async throws -> LoggedMealResult {
        FirebaseBootstrap.configureIfNeeded()

        let trimmedText = foodText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || !images.isEmpty else {
            throw AppError.invalidInput("Please describe what you ate.")
        }

        await appConfigService.fetchConfig()
        guard appConfigService.isAppVersionValid() else {
            throw AppError.invalidInput("App update required.")
        }

        let resolvedMealType = mealType ?? MealTypeInference.determineMealType(text: trimmedText)
        let openAIService = try OpenAIService()
        let response = try await openAIService.logMeal(
            foodText: trimmedText,
            mealType: resolvedMealType.rawValue,
            images: images
        )

        let displayText = Self.displayText(
            input: trimmedText,
            response: response
        )
        let jsonData = try JSONEncoder().encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        let entry = MealEntry(
            id: UUID(),
            timestamp: selectedDate,
            createdAt: Date(),
            foodText: displayText,
            mealType: response.mealType,
            totalCalories: response.totalCalories,
            rawResponseJson: jsonString,
            hasImage: !images.isEmpty
        )

        modelContext.insert(entry)
        try modelContext.save()

        if !images.isEmpty, let firstImage = images.first {
            ImageUtils.saveMealImageLocally(image: firstImage, forMealId: entry.id)
        }

        WidgetCenter.shared.reloadAllTimelines()

        Task { @MainActor in
            await cloudSyncService.syncMealToCloud(entry)
            await HealthKitService.shared.saveMealEntry(entry)
        }

        Task { @MainActor in
            await NotificationService.shared.rescheduleNotificationsIfNeeded(modelContext: modelContext)
        }

        AnalyticsService.trackMealLogged(
            mealType: entry.mealType,
            totalCalories: entry.totalCalories,
            itemCount: response.items.count,
            hasImage: !images.isEmpty
        )

        RatingService.shared.incrementMealLogCount()
        return LoggedMealResult(entry: entry, response: response)
    }

    private static func displayText(input: String, response: MealLogResponse) -> String {
        if !input.isEmpty && input != "Image uploaded" {
            return input
        }

        let itemNames = response.items
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !itemNames.isEmpty {
            return itemNames.joined(separator: ", ")
        }

        return "\(response.mealType.capitalized) Meal"
    }
}
