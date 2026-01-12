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
    
    init(id: UUID = UUID(), timestamp: Date = Date(), createdAt: Date? = nil, foodText: String, mealType: String, totalCalories: Double, rawResponseJson: String, hasImage: Bool? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.createdAt = createdAt ?? Date()
        self.foodText = foodText
        self.mealType = mealType
        self.totalCalories = totalCalories
        self.rawResponseJson = rawResponseJson
        self.hasImage = hasImage
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
    
    // Macros computed properties (extracted from rawResponseJson)
    nonisolated var protein: Double? {
        let result = response?.protein
        // #region agent log
        if let debugLogData = try? JSONSerialization.data(withJSONObject: ["location": "MealEntry.swift:52", "message": "MealEntry.protein computed property", "data": ["protein": result as Any, "responseExists": response != nil, "responseProtein": response?.protein as Any, "rawResponseJsonLength": rawResponseJson.count], "timestamp": Date().timeIntervalSince1970 * 1000, "sessionId": "debug-session", "runId": "run1", "hypothesisId": "C"]), let logString = String(data: debugLogData, encoding: .utf8) {
            try? (logString + "\n").write(toFile: "/Users/ajohri/Documents/Antriksh Personal/LogCal/logcal/.cursor/debug.log", atomically: false, encoding: .utf8)
        }
        // #endregion
        return result
    }
    
    nonisolated var carbs: Double? {
        response?.carbs
    }
    
    nonisolated var fat: Double? {
        response?.fat
    }
}

