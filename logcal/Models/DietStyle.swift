//
//  DietStyle.swift
//  logcal
//
//  Created by Antigravity on 04/06/26.
//

import Foundation

enum DietStyle: String, CaseIterable, Identifiable {
    case balanced = "Balanced"
    case highProtein = "High Protein"
    case lowCarb = "Low Carb"
    case keto = "Ketogenic"
    case custom = "Custom"
    
    var id: String { self.rawValue }
    
    var macroPercentages: (protein: Double, carbs: Double, fat: Double) {
        switch self {
        case .balanced:
            return (0.30, 0.40, 0.30)
        case .highProtein:
            return (0.40, 0.30, 0.30)
        case .lowCarb:
            return (0.25, 0.15, 0.60)
        case .keto:
            return (0.20, 0.05, 0.75)
        case .custom:
            return (0.30, 0.40, 0.30) // Fallback default
        }
    }
    
    static func calculateGrams(calories: Double, proteinPercent: Double, carbsPercent: Double, fatPercent: Double) -> (protein: Double, carbs: Double, fat: Double) {
        let pGrams = (calories * proteinPercent) / 4.0
        let cGrams = (calories * carbsPercent) / 4.0
        let fGrams = (calories * fatPercent) / 9.0
        
        // Round to nearest integer for clean user display
        return (round(pGrams), round(cGrams), round(fGrams))
    }
}
