//
//  CompletedMealPreview.swift
//  logcal
//

import Foundation

struct CompletedMealPreview: Identifiable, Equatable {
    let id: UUID
    var response: MealLogResponse
    var foodText: String
    var mealType: MealType
    var date: Date
    var isRefining: Bool = false
    var refineError: String? = nil

    static func == (lhs: CompletedMealPreview, rhs: CompletedMealPreview) -> Bool {
        lhs.id == rhs.id &&
        lhs.response.totalCalories == rhs.response.totalCalories &&
        lhs.isRefining == rhs.isRefining &&
        lhs.refineError == rhs.refineError &&
        lhs.foodText == rhs.foodText
    }
}
