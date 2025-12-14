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
        print("DEBUG: Checking for explicit meal type in text: \(text)")
        
        if lowercased.contains("breakfast") || lowercased.contains("brunch") {
            print("DEBUG: Detected breakfast/brunch")
            return .breakfast
        }
        if lowercased.contains("lunch") {
            print("DEBUG: Detected lunch")
            return .lunch
        }
        if lowercased.contains("dinner") {
            print("DEBUG: Detected dinner")
            return .dinner
        }
        if lowercased.contains("snack") {
            print("DEBUG: Detected snack")
            return .snack
        }
        
        print("DEBUG: No explicit meal type found")
        return nil
    }
    
    static func inferMealTypeFromISTNow() -> MealType {
        let istTimeZone = TimeZone(identifier: "Asia/Kolkata")!
        let now = Date()
        let calendar = Calendar.current
        var istCalendar = calendar
        istCalendar.timeZone = istTimeZone
        
        let hour = istCalendar.component(.hour, from: now)
        print("DEBUG: Current IST hour: \(hour)")
        
        let mealType: MealType
        switch hour {
        case 5...10:
            mealType = .breakfast
        case 11...15:
            mealType = .lunch
        case 16...18:
            mealType = .snack
        case 19...23:
            mealType = .dinner
        case 0...4:
            mealType = .snack
        default:
            mealType = .snack
        }
        
        print("DEBUG: Inferred meal type from IST: \(mealType.rawValue)")
        return mealType
    }
    
    static func determineMealType(text: String) -> MealType {
        if let explicit = detectExplicitMealType(text: text) {
            return explicit
        }
        return inferMealTypeFromISTNow()
    }
}

