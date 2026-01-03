//
//  IntentHandler.swift
//  LogCalIntents
//
//  Created for Siri integration
//

import Intents
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore


class IntentHandler: INExtension, LogMealIntentHandling {
    
    override init() {
            // Log immediately - before anything else
            print("DEBUG: [Siri] ===== IntentHandler.init() START =====")
            // #region agent log
            print("DEBUG_LOG [IntentHandler.swift:init] IntentHandler extension initialized - START")
            // #endregion
            
            super.init()
            print("DEBUG: [Siri] super.init() completed")
            
            // Initialize Firebase if not already initialized - wrap in do-catch to prevent crashes
            do {
            if FirebaseApp.app() == nil {
                    // #region agent log
                    print("DEBUG_LOG [IntentHandler.swift:init] Initializing Firebase in extension")
                    // #endregion
                    print("DEBUG: [Siri] Initializing Firebase in extension...")
                FirebaseApp.configure()
                    print("DEBUG: [Siri] Firebase configured successfully")
                } else {
                    print("DEBUG: [Siri] Firebase already initialized")
                }
            } catch {
                // #region agent log
                print("DEBUG_LOG [IntentHandler.swift:init] Firebase initialization failed: \(error)")
                // #endregion
                print("DEBUG: [Siri] ERROR: Firebase initialization failed: \(error)")
                // Continue anyway - Firebase might work later
            }
            
            // #region agent log
            print("DEBUG_LOG [IntentHandler.swift:init] IntentHandler initialization complete")
            // #endregion
            print("DEBUG: [Siri] ===== IntentHandler.init() COMPLETE =====")
        }
    
    func handle(intent: LogMealIntent, completion: @escaping (LogMealIntentResponse) -> Void) {
        // #region agent log
        print("DEBUG_LOG [IntentHandler.swift:handle] handle() called - foodDescription: \(intent.foodDescription ?? "nil"), mealType: \(intent.mealType ?? "nil")")
        // #endregion
        print("DEBUG: [Siri] IntentHandler.handle() called")
        print("DEBUG: [Siri] Food description: \(intent.foodDescription ?? "nil")")
        print("DEBUG: [Siri] Meal type: \(intent.mealType ?? "nil")")
        
        // #region agent log
        let rawFoodDesc = intent.foodDescription ?? "nil"
        let trimmedFoodDesc = intent.foodDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        print("DEBUG_LOG [IntentHandler.swift:handle] Parameter check - raw: '\(rawFoodDesc)', trimmed: '\(trimmedFoodDesc)', isEmpty: \(trimmedFoodDesc.isEmpty)")
        // #endregion
        
        // When called from Shortcuts app without parameters, open the app
        // Trim whitespace to handle empty strings or whitespace-only strings
        guard let foodDescriptionRaw = intent.foodDescription,
              !foodDescriptionRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // #region agent log
            print("DEBUG_LOG [IntentHandler.swift:handle] No food description - opening app via continueInApp")
            // #endregion
            print("DEBUG: [Siri] No food description provided - opening app")
            print("DEBUG: [Siri] Creating NSUserActivity with type: com.serene.logcal.log-meal")
            
            // Create user activity to open the app
            // iOS appends "Intent" to the Intent name for the activity type
            let userActivity = NSUserActivity(activityType: "LogMealIntentIntent")
            userActivity.title = "Log a meal"
            userActivity.isEligibleForHandoff = false
            userActivity.isEligibleForSearch = false
            
            // Return continueInApp to open the main app
            let response = LogMealIntentResponse(code: .continueInApp, userActivity: userActivity)
            response.errorMessage = "Opening LogCal to log your meal..."
            
            // #region agent log
            print("DEBUG_LOG [IntentHandler.swift:handle] Returning continueInApp response - code: \(response.code.rawValue), hasUserActivity: \(userActivity != nil)")
            // #endregion
            print("DEBUG: [Siri] Returning continueInApp response (code: \(response.code.rawValue))")
            
            completion(response)
            return
        }
        
        // Trim the food description to remove any leading/trailing whitespace
        let foodDescription = foodDescriptionRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // #region agent log
        print("DEBUG_LOG [IntentHandler.swift:handle] Proceeding with meal logging - foodDescription: '\(foodDescription)'")
        // #endregion
        print("DEBUG: [Siri] Proceeding with meal logging - foodDescription: '\(foodDescription)'")
        
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
        // #region agent log
        print("DEBUG_LOG [IntentHandler.swift:confirm] confirm() called - foodDescription: \(intent.foodDescription ?? "nil"), mealType: \(intent.mealType ?? "nil")")
        // #endregion
        // Optional: Add confirmation logic here
        // For now, we'll proceed directly
        let response = LogMealIntentResponse(code: .ready, userActivity: nil)
        completion(response)
    }
    
    func resolveFoodDescription(for intent: LogMealIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        // #region agent log
        let rawValue = intent.foodDescription ?? "nil"
        let trimmedValue = intent.foodDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        print("DEBUG_LOG [IntentHandler.swift:resolveFoodDescription] resolveFoodDescription() called - raw: '\(rawValue)', trimmed: '\(trimmedValue)', isEmpty: \(trimmedValue.isEmpty)")
        // #endregion
        print("DEBUG: [Siri] resolveFoodDescription() called - value: '\(intent.foodDescription ?? "nil")'")
        
        // Trim and check if non-empty
        if let foodDescription = intent.foodDescription,
           !foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmed = foodDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            // #region agent log
            print("DEBUG_LOG [IntentHandler.swift:resolveFoodDescription] Returning success with trimmed value: '\(trimmed)'")
            // #endregion
            print("DEBUG: [Siri] resolveFoodDescription() returning success: '\(trimmed)'")
            completion(.success(with: trimmed))
        } else {
            // #region agent log
            print("DEBUG_LOG [IntentHandler.swift:resolveFoodDescription] Returning needsValue() - Siri will prompt user")
            // #endregion
            print("DEBUG: [Siri] resolveFoodDescription() returning needsValue()")
            // When called from Shortcuts app, this will prompt user to configure the shortcut
            // When called from Siri, this will make Siri ask "What did you eat?"
            completion(.needsValue())
        }
    }
    
    func resolveMealType(for intent: LogMealIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        // #region agent log
        print("DEBUG_LOG [IntentHandler.swift:resolveMealType] resolveMealType() called - mealType: \(intent.mealType ?? "nil")")
        // #endregion
        if let mealType = intent.mealType, !mealType.isEmpty {
            // #region agent log
            print("DEBUG_LOG [IntentHandler.swift:resolveMealType] Returning success with value: \(mealType)")
            // #endregion
            completion(.success(with: mealType))
        } else {
            // Use inferred meal type
            let inferredType = MealTypeInferenceHelper.inferMealType()
            // #region agent log
            print("DEBUG_LOG [IntentHandler.swift:resolveMealType] Returning inferred type: \(inferredType)")
            // #endregion
            completion(.success(with: inferredType))
        }
    }
}

