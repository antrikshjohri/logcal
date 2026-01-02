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
    
    init(id: UUID = UUID(), timestamp: Date = Date(), createdAt: Date? = nil, foodText: String, mealType: String, totalCalories: Double, rawResponseJson: String) {
        self.id = id
        self.timestamp = timestamp
        self.createdAt = createdAt ?? Date()
        self.foodText = foodText
        self.mealType = mealType
        self.totalCalories = totalCalories
        self.rawResponseJson = rawResponseJson
    }
    
    // Helper to get createdAt with fallback to timestamp for old records
    var effectiveCreatedAt: Date {
        createdAt ?? timestamp
    }
    
    nonisolated var response: MealLogResponse? {
        guard let data = rawResponseJson.data(using: .utf8) else { return nil }
        // Decode in nonisolated context
        // Use a nonisolated decoder to avoid actor isolation issues
        let decoder = JSONDecoder()
        return try? decoder.decode(MealLogResponse.self, from: data)
    }
}

