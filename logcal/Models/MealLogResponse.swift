//
//  MealLogResponse.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation

struct MealLogResponse: Codable, Equatable {
    let mealType: String
    let totalCalories: Double
    let protein: Double?  // grams
    let carbs: Double?    // grams
    let fat: Double?      // grams
    let items: [MealItem]
    let needsClarification: Bool
    let clarifyingQuestion: String?
    
    enum CodingKeys: String, CodingKey {
        case mealType = "meal_type"
        case totalCalories = "total_calories"
        case protein
        case carbs
        case fat
        case items
        case needsClarification = "needs_clarification"
        case clarifyingQuestion = "clarifying_question"
    }
}

struct MealItem: Codable, Equatable {
    let name: String
    let quantity: String
    let calories: Double
    let protein: Double?  // grams
    let carbs: Double?    // grams
    let fat: Double?      // grams
    let assumptions: String?
    let confidence: Double
}

