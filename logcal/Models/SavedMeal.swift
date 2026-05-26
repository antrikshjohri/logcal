//
//  SavedMeal.swift
//  logcal
//

import Foundation
import SwiftData

@Model
final class SavedMeal: Identifiable {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var foodText: String
    var mealType: String
    var totalCalories: Double
    var rawResponseJson: String
    var sourceMealId: UUID?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        title: String,
        foodText: String,
        mealType: String,
        totalCalories: Double,
        rawResponseJson: String,
        sourceMealId: UUID? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.foodText = foodText
        self.mealType = mealType
        self.totalCalories = totalCalories
        self.rawResponseJson = rawResponseJson
        self.sourceMealId = sourceMealId
    }

    nonisolated var response: MealLogResponse? {
        guard let data = rawResponseJson.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MealLogResponse.self, from: data)
    }

    nonisolated var protein: Double? {
        response?.resolvedMealMacrosForDisplay()?.protein
    }

    nonisolated var carbs: Double? {
        response?.resolvedMealMacrosForDisplay()?.carbs
    }

    nonisolated var fat: Double? {
        response?.resolvedMealMacrosForDisplay()?.fat
    }
}

enum SavedMealTitle {
    static func suggestedTitle(foodText: String, response: MealLogResponse) -> String {
        let trimmed = foodText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != "Image uploaded" {
            return String(trimmed.prefix(140))
        }

        let itemNames = response.items
            .prefix(3)
            .map(\.name)
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        if !itemNames.isEmpty {
            return String(itemNames.prefix(140))
        }

        return "\(response.mealType.capitalized) meal"
    }
}

enum SavedMealServing {
    static let commonMultipliers = [0.5, 1.0, 1.5, 2.0]

    static func label(for multiplier: Double) -> String {
        multiplier == floor(multiplier)
            ? "\(Int(multiplier))x"
            : String(format: "%.1fx", multiplier)
    }
}

enum SavedMealMatcher {
    static func matches(_ savedMeal: SavedMeal, meal: MealEntry) -> Bool {
        if savedMeal.sourceMealId == meal.id {
            return true
        }

        return savedMeal.sourceMealId == nil
            && savedMeal.foodText == meal.foodText
            && savedMeal.mealType == meal.mealType
            && savedMeal.rawResponseJson == meal.rawResponseJson
            && abs(savedMeal.totalCalories - meal.totalCalories) < 0.01
    }
}
