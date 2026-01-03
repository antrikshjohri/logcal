//
//  IntentHandler.swift
//  LogCalIntents
//
//  Created for Siri integration
//

import Intents
import Foundation

class IntentHandler: INExtension, LogMealIntentHandling {
    
    func handle(intent: LogMealIntent, completion: @escaping (LogMealIntentResponse) -> Void) {
        print("DEBUG: [Siri] IntentHandler.handle() called")
        print("DEBUG: [Siri] Food description: \(intent.foodDescription ?? "nil")")
        print("DEBUG: [Siri] Meal type: \(intent.mealType ?? "nil")")
        
        guard let foodDescription = intent.foodDescription, !foodDescription.isEmpty else {
            print("DEBUG: [Siri] No food description provided")
            let response = LogMealIntentResponse(code: .failure, userActivity: nil)
            response.errorMessage = "Please tell me what you ate."
            completion(response)
            return
        }
        
        // Determine meal type
        let mealType = intent.mealType ?? MealTypeInferenceHelper.inferMealType()
        
        // Log the meal using the extension service
        Task {
            do {
                let result = try await ExtensionMealService.shared.logMeal(
                    foodText: foodDescription,
                    mealType: mealType
                )
                
                print("DEBUG: [Siri] Successfully logged meal: \(result.totalCalories) calories")
                
                // Create success response
                let response = LogMealIntentResponse(code: .success, userActivity: nil)
                response.calories = NSNumber(value: result.totalCalories)
                response.mealType = result.mealType
                
                // Format response message
                let caloriesInt = Int(result.totalCalories)
                response.message = "I've logged \(caloriesInt) calories for your \(result.mealType)."
                
                completion(response)
            } catch {
                print("DEBUG: [Siri] Error logging meal: \(error)")
                
                let response = LogMealIntentResponse(code: .failure, userActivity: nil)
                
                // Provide user-friendly error message
                if let appError = error as? AppError {
                    response.errorMessage = appError.errorDescription ?? "Failed to log meal. Please try again."
                } else {
                    response.errorMessage = "I couldn't log your meal. Please try again or use the LogCal app."
                }
                
                completion(response)
            }
        }
    }
    
    func confirm(intent: LogMealIntent, completion: @escaping (LogMealIntentResponse) -> Void) {
        // Optional: Add confirmation logic here
        // For now, we'll proceed directly
        let response = LogMealIntentResponse(code: .ready, userActivity: nil)
        completion(response)
    }
    
    func resolveFoodDescription(for intent: LogMealIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let foodDescription = intent.foodDescription, !foodDescription.isEmpty {
            completion(.success(with: foodDescription))
        } else {
            completion(.needsValue())
        }
    }
    
    func resolveMealType(for intent: LogMealIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let mealType = intent.mealType, !mealType.isEmpty {
            completion(.success(with: mealType))
        } else {
            // Use inferred meal type
            let inferredType = MealTypeInferenceHelper.inferMealType()
            completion(.success(with: inferredType))
        }
    }
}

