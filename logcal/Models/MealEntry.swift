//
//  MealEntry.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import SwiftData

@Model
final class MealEntry: Identifiable {
    var id: UUID
    var timestamp: Date          // User-selected date for the meal
    var createdAt: Date?         // When the record was actually created (optional for migration)
    var foodText: String
    var mealType: String
    var totalCalories: Double
    var rawResponseJson: String
    var hasImage: Bool?           // Indicates if an image was used for this meal (optional for backward compatibility)
    var sourceSavedMealId: UUID? = nil
    var deleted: Bool = false
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        createdAt: Date? = nil,
        foodText: String,
        mealType: String,
        totalCalories: Double,
        rawResponseJson: String,
        hasImage: Bool? = nil,
        sourceSavedMealId: UUID? = nil,
        deleted: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.createdAt = createdAt ?? Date()
        self.foodText = foodText
        self.mealType = mealType
        self.totalCalories = totalCalories
        self.rawResponseJson = rawResponseJson
        self.hasImage = hasImage
        self.sourceSavedMealId = sourceSavedMealId
        self.deleted = deleted
    }
    
    // Helper to get createdAt with fallback to timestamp for old records
    var effectiveCreatedAt: Date {
        createdAt ?? timestamp
    }
    
    // Helper to check if image was used (handles optional)
    var hasImageValue: Bool {
        hasImage ?? false
    }
    
    nonisolated var response: MealLogResponse? {
        guard let data = rawResponseJson.data(using: .utf8) else { return nil }
        // Decode in nonisolated context
        // Use a nonisolated decoder to avoid actor isolation issues
        let decoder = JSONDecoder()
        return try? decoder.decode(MealLogResponse.self, from: data)
    }
    
    // Macros: prefer sum of line items when every item has P/C/F so totals match the breakdown (same as post-log preview).
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

