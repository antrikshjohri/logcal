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
        case mealTypeCamel = "mealType"
        case totalCalories = "total_calories"
        case totalCaloriesCamel = "totalCalories"
        case protein
        case carbs
        case fat
        case items
        case needsClarification = "needs_clarification"
        case needsClarificationCamel = "needsClarification"
        case clarifyingQuestion = "clarifying_question"
        case clarifyingQuestionCamel = "clarifyingQuestion"
    }

    init(
        mealType: String,
        totalCalories: Double,
        protein: Double?,
        carbs: Double?,
        fat: Double?,
        items: [MealItem],
        needsClarification: Bool,
        clarifyingQuestion: String?
    ) {
        self.mealType = mealType
        self.totalCalories = totalCalories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.items = items
        self.needsClarification = needsClarification
        self.clarifyingQuestion = clarifyingQuestion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try snake_case first, fall back to camelCase
        if let type = try? container.decode(String.self, forKey: .mealType) {
            self.mealType = type
        } else {
            self.mealType = try container.decode(String.self, forKey: .mealTypeCamel)
        }
        
        if let calories = try? container.decode(Double.self, forKey: .totalCalories) {
            self.totalCalories = calories
        } else {
            self.totalCalories = try container.decode(Double.self, forKey: .totalCaloriesCamel)
        }
        
        self.protein = try container.decodeIfPresent(Double.self, forKey: .protein)
        self.carbs = try container.decodeIfPresent(Double.self, forKey: .carbs)
        self.fat = try container.decodeIfPresent(Double.self, forKey: .fat)
        self.items = try container.decode([MealItem].self, forKey: .items)
        
        if let needsClar = try? container.decode(Bool.self, forKey: .needsClarification) {
            self.needsClarification = needsClar
        } else if let needsClarCamel = try? container.decode(Bool.self, forKey: .needsClarificationCamel) {
            self.needsClarification = needsClarCamel
        } else {
            self.needsClarification = false
        }
        
        if let clarifyingQ = try? container.decode(String.self, forKey: .clarifyingQuestion) {
            self.clarifyingQuestion = clarifyingQ
        } else if let clarifyingQCamel = try? container.decode(String.self, forKey: .clarifyingQuestionCamel) {
            self.clarifyingQuestion = clarifyingQCamel
        } else {
            self.clarifyingQuestion = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mealType, forKey: .mealType)
        try container.encode(totalCalories, forKey: .totalCalories)
        try container.encodeIfPresent(protein, forKey: .protein)
        try container.encodeIfPresent(carbs, forKey: .carbs)
        try container.encodeIfPresent(fat, forKey: .fat)
        try container.encode(items, forKey: .items)
        try container.encode(needsClarification, forKey: .needsClarification)
        try container.encodeIfPresent(clarifyingQuestion, forKey: .clarifyingQuestion)
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
    let confidence: Double?
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
