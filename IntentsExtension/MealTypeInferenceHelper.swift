//
//  MealTypeInferenceHelper.swift
//  LogCalIntents
//
//  Helper to infer meal type for Siri intents (without SwiftData dependencies)
//

import Foundation

/// Helper to infer meal type for Siri intents
/// This is a simplified version that doesn't depend on SwiftData
enum MealTypeInferenceHelper {
    /// Infer meal type based on current time (IST)
    static func inferMealType() -> String {
        let istTimeZone = TimeZone(identifier: "Asia/Kolkata") ?? TimeZone.current
        var calendar = Calendar.current
        calendar.timeZone = istTimeZone
        
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        switch hour {
        case 5...10:
            return "breakfast"
        case 11...15:
            return "lunch"
        case 16...18:
            return "snack"
        case 19...23:
            return "dinner"
        case 0...4:
            return "lateNightSnack"
        default:
            return "snack"
        }
    }
    
    /// Infer meal type from text (simplified version)
    static func inferMealType(from text: String) -> String {
        let lowercased = text.lowercased()
        
        if lowercased.contains("breakfast") || lowercased.contains("morning") {
            return "breakfast"
        } else if lowercased.contains("lunch") || lowercased.contains("noon") {
            return "lunch"
        } else if lowercased.contains("dinner") || lowercased.contains("evening") || lowercased.contains("night") {
            return "dinner"
        } else if lowercased.contains("snack") {
            return "snack"
        }
        
        // Default to time-based inference
        return inferMealType()
    }
}

