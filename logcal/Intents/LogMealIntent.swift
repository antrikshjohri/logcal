//
//  LogMealIntent.swift
//  logcal
//
//  Siri and Shortcuts support for logging meals with LogCal.
//

import AppIntents
import Foundation
import SwiftData

struct LogMealIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Meal"
    static var description = IntentDescription("Log a meal in LogCal with AI calorie and macro estimates.")
    static var openAppWhenRun = false

    @Parameter(
        title: "Meal",
        description: "Describe what you ate.",
        requestValueDialog: "What did you eat?"
    )
    var mealDescription: String?

    @Parameter(
        title: "Meal Type",
        description: "Choose breakfast, lunch, dinner, or snack."
    )
    var mealType: MealType?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$mealDescription)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let providedDescription = mealDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedDescription: String

        if let providedDescription, !providedDescription.isEmpty {
            resolvedDescription = providedDescription
        } else {
            resolvedDescription = try await $mealDescription
                .requestValue("What did you eat?")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let trimmed = resolvedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw $mealDescription.needsValueError("What did you eat?")
        }

        FirebaseBootstrap.configureIfNeeded()
        let context = ModelContext(logcalApp.sharedModelContainer)
        let result = try await MealLoggingService().logMeal(
            foodText: trimmed,
            mealType: mealType,
            selectedDate: Date(),
            modelContext: context
        )

        let calories = Int(result.response.totalCalories.rounded())
        return .result(
            dialog: "Logged \(result.entry.foodText) for \(calories) calories."
        )
    }
}

struct LogCalShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMealIntent(),
            phrases: [
                "Log a meal in \(.applicationName)",
                "Track food in \(.applicationName)",
                "Add a meal to \(.applicationName)"
            ],
            shortTitle: "Log Meal",
            systemImageName: "fork.knife"
        )
    }
}
