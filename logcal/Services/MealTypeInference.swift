//
//  MealTypeInference.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation

enum MealType: String, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
}

struct MealTypeInference {
    static func detectExplicitMealType(text: String) -> MealType? {
        let lowercased = text.lowercased()
        
        if lowercased.contains("breakfast") || lowercased.contains("brunch") {
            return .breakfast
        }
        if lowercased.contains("lunch") {
            return .lunch
        }
        if lowercased.contains("dinner") {
            return .dinner
        }
        if lowercased.contains("snack") {
            return .snack
        }
        
        return nil
    }
    
    static func inferMealTypeFromISTNow() -> MealType {
        guard let istTimeZone = TimeZone(identifier: Constants.Locale.timeZone) else {
            return .snack // Default fallback
        }
        let now = Date()
        let calendar = Calendar.current
        var istCalendar = calendar
        istCalendar.timeZone = istTimeZone
        
        let hour = istCalendar.component(.hour, from: now)
        
        switch hour {
        case Constants.MealTypeRanges.breakfast:
            return .breakfast
        case Constants.MealTypeRanges.lunch:
            return .lunch
        case Constants.MealTypeRanges.snack:
            return .snack
        case Constants.MealTypeRanges.dinner:
            return .dinner
        case Constants.MealTypeRanges.lateNightSnack:
            return .snack
        default:
            return .snack
        }
    }
    
    static func determineMealType(text: String) -> MealType {
        if let explicit = detectExplicitMealType(text: text) {
            return explicit
        }
        return inferMealTypeFromISTNow()
    }
}

