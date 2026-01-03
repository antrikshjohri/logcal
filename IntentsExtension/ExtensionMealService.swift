//
//  ExtensionMealService.swift
//  LogCalIntents
//
//  Service for handling meal logging from Siri Intents Extension
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Service to handle meal logging from Intents Extension
/// This service saves directly to Firestore (extensions can't access SwiftData)
class ExtensionMealService {
    static let shared = ExtensionMealService()
    
    private let firebaseService = FirebaseService()
    private let firestoreService = FirestoreService()
    
    private init() {
        // Ensure Firebase is configured
        // Firebase should be initialized in the extension's Info.plist
    }
    
    /// Log a meal from Siri intent
    /// Returns MealLogResponse with calories and meal details
    func logMeal(foodText: String, mealType: String) async throws -> MealLogResponse {
        print("DEBUG: [Extension] ExtensionMealService.logMeal() called")
        print("DEBUG: [Extension] Food text: \(foodText)")
        print("DEBUG: [Extension] Meal type: \(mealType)")
        
        // Ensure user is authenticated (sign in anonymously if needed)
        if !firebaseService.isAuthenticated {
            print("DEBUG: [Extension] User not authenticated, signing in anonymously...")
            try await firebaseService.signInAnonymously()
            print("DEBUG: [Extension] Anonymous sign-in completed")
        }
        
        // Call OpenAI via Firebase Functions to get calorie estimate
        let response = try await firebaseService.logMeal(foodText: foodText, mealType: mealType)
        
        print("DEBUG: [Extension] Received response: \(response.totalCalories) calories")
        
        // Save to Firestore directly (extensions can't use SwiftData)
        let entry = MealEntry(
            id: UUID(),
            timestamp: Date(),
            createdAt: Date(),
            foodText: foodText,
            mealType: response.mealType,
            totalCalories: response.totalCalories,
            rawResponseJson: try encodeResponse(response)
        )
        
        do {
            try await firestoreService.saveMealEntry(entry)
            print("DEBUG: [Extension] Successfully saved meal to Firestore: \(entry.id)")
        } catch {
            print("DEBUG: [Extension] Error saving to Firestore: \(error)")
            // Don't throw - the meal was logged successfully, just sync failed
            // The main app will sync on next launch
        }
        
        return response
    }
    
    /// Encode MealLogResponse to JSON string
    private func encodeResponse(_ response: MealLogResponse) throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

