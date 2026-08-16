//
//  PendingMealLog.swift
//  logcal
//

import Foundation
import UIKit

enum PendingLogStatus: Equatable {
    case processing
    case completed(response: MealLogResponse, entryId: UUID)
    case failed(error: String)
}

struct PendingMealLog: Identifiable, Equatable {
    let id: UUID
    let foodText: String
    let images: [UIImage]
    let mealType: MealType
    let selectedDate: Date
    let createdAt: Date
    var isPreviewOnly: Bool = false
    var status: PendingLogStatus
    
    var displayText: String {
        let trimmed = foodText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        if !images.isEmpty {
            return "Photo meal"
        }
        return "\(mealType.rawValue.capitalized) log"
    }
    
    static func == (lhs: PendingMealLog, rhs: PendingMealLog) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.foodText == rhs.foodText && lhs.mealType == rhs.mealType
    }
}
