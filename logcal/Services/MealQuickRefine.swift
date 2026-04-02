//
//  MealQuickRefine.swift
//  logcal
//

import Foundation
import SwiftData

/// Re-runs the LLM with a user correction and updates a `MealEntry` (local + optional cloud sync).
enum MealQuickRefine {
    @MainActor
    static func apply(
        entry: MealEntry,
        correctionPrompt: String,
        modelContext: ModelContext,
        openAIService: OpenAIService,
        cloudSyncService: CloudSyncService
    ) async throws -> MealLogResponse {
        let trimmed = correctionPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("DEBUG: [MealQuickRefine] empty prompt")
            throw AppError.unknown(NSError(
                domain: "MealQuickRefine",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Enter a correction first."]
            ))
        }
        guard let previous = entry.response else {
            print("DEBUG: [MealQuickRefine] no decoded response entry=\(entry.id)")
            throw AppError.parseError
        }
        print("DEBUG: [MealQuickRefine] refining entry=\(entry.id) promptLen=\(trimmed.count)")
        let refined = try await openAIService.refineMeal(
            foodText: entry.foodText,
            mealType: entry.mealType,
            previous: previous,
            correctionPrompt: trimmed
        )
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(refined)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
        entry.totalCalories = refined.totalCalories
        entry.mealType = refined.mealType
        entry.rawResponseJson = jsonString
        // History rows use `foodText`; keep it aligned with the refined breakdown (detail JSON already matched).
        let summary = summaryLine(from: refined)
        if !summary.isEmpty {
            entry.foodText = summary
            let preview = summary.count > 80 ? String(summary.prefix(80)) + "…" : summary
            print("DEBUG: [MealQuickRefine] updated foodText for history: \(preview)")
        } else {
            print("DEBUG: [MealQuickRefine] foodText unchanged (no items to summarize)")
        }
        try modelContext.save()
        print("DEBUG: [MealQuickRefine] saved refined meal id=\(entry.id) cal=\(refined.totalCalories)")
        Task {
            await cloudSyncService.syncMealToCloud(entry)
        }
        Task {
            await NotificationService.shared.rescheduleNotificationsIfNeeded(modelContext: modelContext)
        }
        return refined
    }

    /// One line for list/detail title: matches refined `items` (same source as breakdown).
    private static func summaryLine(from response: MealLogResponse) -> String {
        response.items.map { item in
            let q = item.quantity.trimmingCharacters(in: .whitespacesAndNewlines)
            return q.isEmpty ? item.name : "\(item.name) (\(q))"
        }.joined(separator: ", ")
    }
}
