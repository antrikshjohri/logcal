//
//  WatchSavedMeal.swift
//  LogCalWatch
//
//  Created by Antriksh Johri on 17/08/26.
//

import Foundation

struct WatchSavedMeal: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let totalCalories: Double
    let mealType: String
    let protein: Double
    let carbs: Double
    let fat: Double
    
    init(
        id: String,
        title: String,
        totalCalories: Double,
        mealType: String = "meal",
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0
    ) {
        self.id = id
        self.title = title
        self.totalCalories = totalCalories
        self.mealType = mealType
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}
