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

extension MealLogResponse {
    func scaled(by multiplier: Double) -> MealLogResponse {
        MealLogResponse(
            mealType: mealType,
            totalCalories: totalCalories * multiplier,
            protein: protein.map { $0 * multiplier },
            carbs: carbs.map { $0 * multiplier },
            fat: fat.map { $0 * multiplier },
            items: items.map { item in
                MealItem(
                    name: item.name,
                    quantity: item.quantity,
                    calories: item.calories * multiplier,
                    protein: item.protein.map { $0 * multiplier },
                    carbs: item.carbs.map { $0 * multiplier },
                    fat: item.fat.map { $0 * multiplier },
                    assumptions: item.assumptions,
                    confidence: item.confidence
                )
            },
            needsClarification: needsClarification,
            clarifyingQuestion: clarifyingQuestion
        )
    }

    /// When every item includes protein, carbs, and fat, set top-level meal macros to their sum so stored JSON matches the breakdown.
    func withMealMacrosAlignedToItems() -> MealLogResponse {
        let items = self.items
        guard !items.isEmpty else { return self }
        let allHaveMacros = items.allSatisfy { $0.protein != nil && $0.carbs != nil && $0.fat != nil }
        guard allHaveMacros else { return self }
        let p = items.reduce(0.0) { $0 + ($1.protein ?? 0) }
        let c = items.reduce(0.0) { $0 + ($1.carbs ?? 0) }
        let f = items.reduce(0.0) { $0 + ($1.fat ?? 0) }
        print("DEBUG: [MealLogResponse] withMealMacrosAlignedToItems P=\(p) C=\(c) F=\(f) items=\(items.count)")
        return MealLogResponse(
            mealType: mealType,
            totalCalories: totalCalories,
            protein: p,
            carbs: c,
            fat: f,
            items: items,
            needsClarification: needsClarification,
            clarifyingQuestion: clarifyingQuestion
        )
    }

    /// Macros for UI: prefer sum of items when every item has P/C/F; else meal-level fields; else sum of items that have all three.
    func resolvedMealMacrosForDisplay() -> (protein: Double, carbs: Double, fat: Double)? {
        let aligned = withMealMacrosAlignedToItems()
        if let p = aligned.protein, let c = aligned.carbs, let f = aligned.fat {
            return (protein: p, carbs: c, fat: f)
        }
        var sp = 0.0, sc = 0.0, sf = 0.0
        var n = 0
        for item in aligned.items {
            if let p = item.protein, let c = item.carbs, let f = item.fat {
                sp += p
                sc += c
                sf += f
                n += 1
            }
        }
        guard n > 0 else { return nil }
        return (protein: sp, carbs: sc, fat: sf)
    }
}
