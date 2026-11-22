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
    var pendingCloudEditId: String? = nil
    
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
    
    var response: MealLogResponse? {
        guard let data = rawResponseJson.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(MealLogResponse.self, from: data)
    }
    
    // Macros: prefer sum of line items when every item has P/C/F so totals match the breakdown (same as post-log preview).
    var protein: Double? {
        response?.resolvedMealMacrosForDisplay()?.protein
    }
    
    var carbs: Double? {
        response?.resolvedMealMacrosForDisplay()?.carbs
    }
    
    var fat: Double? {
        response?.resolvedMealMacrosForDisplay()?.fat
    }

    var fiber: Double? {
        response?.resolvedMealMacrosForDisplay()?.fiber
    }

    struct CloudSyncState: Equatable {
        let timestamp: Date
        let foodText: String
        let mealType: String
        let totalCalories: Double
        let rawResponseJson: String
        let hasImage: Bool
        let deleted: Bool
        let pendingEditId: String?
    }

    var cloudSyncState: CloudSyncState {
        CloudSyncState(timestamp: timestamp, foodText: foodText, mealType: mealType,
                       totalCalories: totalCalories, rawResponseJson: rawResponseJson,
                       hasImage: hasImageValue, deleted: deleted, pendingEditId: pendingCloudEditId)
    }

    /// Preserve pending edits and changes made after a cloud refresh began.
    func mergeCloudVersion(_ cloud: MealEntry, unchangedSince baseline: CloudSyncState?) -> Bool {
        guard pendingCloudEditId == nil, cloudSyncState == baseline,
              cloudSyncState != cloud.cloudSyncState else { return false }
        deleted = cloud.deleted
        foodText = cloud.foodText
        mealType = cloud.mealType
        totalCalories = cloud.totalCalories
        rawResponseJson = cloud.rawResponseJson
        timestamp = cloud.timestamp
        hasImage = cloud.hasImage
        return true
    }
}

