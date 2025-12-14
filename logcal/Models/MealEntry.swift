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
    var timestamp: Date
    var foodText: String
    var mealType: String
    var totalCalories: Double
    var rawResponseJson: String
    
    init(id: UUID = UUID(), timestamp: Date = Date(), foodText: String, mealType: String, totalCalories: Double, rawResponseJson: String) {
        self.id = id
        self.timestamp = timestamp
        self.foodText = foodText
        self.mealType = mealType
        self.totalCalories = totalCalories
        self.rawResponseJson = rawResponseJson
    }
    
    var response: MealLogResponse? {
        guard let data = rawResponseJson.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(MealLogResponse.self, from: data)
    }
}

