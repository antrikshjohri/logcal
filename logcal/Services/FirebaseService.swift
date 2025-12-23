//
//  FirebaseService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import FirebaseFunctions
import FirebaseAuth

struct FirebaseService {
    private let functions = Functions.functions()
    
    /// Log a meal using Firebase Functions (requires authentication)
    func logMeal(foodText: String, mealType: String) async throws -> MealLogResponse {
        // Ensure user is authenticated (Firebase Functions onCall handles auth automatically)
        if !isAuthenticated {
            print("DEBUG: User not authenticated, attempting anonymous sign-in...")
            try await signInAnonymously()
            print("DEBUG: Anonymous sign-in successful")
        }
        
        // Prepare request data
        let requestData: [String: Any] = [
            "foodText": foodText,
            "mealType": mealType
        ]
        
        // Call Firebase Function (onCall automatically includes auth token)
        let function = functions.httpsCallable("logMeal")
        
        do {
            print("DEBUG: Calling Firebase Function with data: \(requestData)")
            let result = try await function.call(requestData)
            
            // Debug: Print the raw response
            print("DEBUG: Firebase Function response type: \(type(of: result.data))")
            print("DEBUG: Firebase Function response: \(result.data)")
            
            // Firebase Functions onCall returns the data directly (not wrapped)
            // The function returns a MealLogResponse object, which gets serialized
            guard let dataDict = result.data as? [String: Any] else {
                print("DEBUG: Response is not a dictionary. Type: \(type(of: result.data)), Value: \(result.data)")
                throw AppError.parseError
            }
            
            // Normalize the dictionary: convert numeric booleans to actual booleans
            var normalizedDict = dataDict
            if let needsClarification = normalizedDict["needs_clarification"] {
                if let num = needsClarification as? NSNumber {
                    normalizedDict["needs_clarification"] = num.boolValue
                } else if let intVal = needsClarification as? Int {
                    normalizedDict["needs_clarification"] = (intVal != 0)
                }
            }
            
            // Normalize items array - convert confidence from string to number if needed
            if var items = normalizedDict["items"] as? [[String: Any]] {
                for i in 0..<items.count {
                    if let confidenceStr = items[i]["confidence"] as? String,
                       let confidenceNum = Double(confidenceStr) {
                        items[i]["confidence"] = confidenceNum
                    } else if let confidenceNum = items[i]["confidence"] as? NSNumber {
                        items[i]["confidence"] = confidenceNum.doubleValue
                    }
                }
                normalizedDict["items"] = items
            }
            
            // Convert to JSON and decode
            // Note: MealLogResponse uses custom CodingKeys, so we don't need keyDecodingStrategy
            let jsonData = try JSONSerialization.data(withJSONObject: normalizedDict, options: [])
            let decoder = JSONDecoder()
            // Don't use keyDecodingStrategy - MealLogResponse has custom CodingKeys
            
            let decoded = try decoder.decode(MealLogResponse.self, from: jsonData)
            print("DEBUG: Successfully decoded MealLogResponse: \(decoded.totalCalories) calories")
            return decoded
        } catch let error as NSError {
            // Debug: Print full error details
            print("DEBUG: Firebase Function error - Domain: \(error.domain), Code: \(error.code), Description: \(error.localizedDescription)")
            print("DEBUG: Error userInfo: \(error.userInfo)")
            
            // Handle Firebase Functions errors
            if error.domain == "FIRFunctionsErrorDomain" || error.domain == "com.firebase.functions" {
                let errorCode = error.code
                var errorMessage = error.localizedDescription
                
                // Try to extract more detailed error message
                if let userInfo = error.userInfo["NSLocalizedDescription"] as? String {
                    errorMessage = userInfo
                }
                
                // Check for underlying error details
                if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                    print("DEBUG: Underlying error: \(underlyingError)")
                    if let underlyingMessage = underlyingError.userInfo[NSLocalizedDescriptionKey] as? String {
                        errorMessage = underlyingMessage
                    }
                }
                
                print("DEBUG: Final error message: \(errorMessage)")
                
                switch errorCode {
                case 1: // UNAUTHENTICATED
                    throw AppError.permissionDenied("Authentication required")
                case 3: // INVALID_ARGUMENT
                    throw AppError.unknown(NSError(domain: "FirebaseFunctions", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                case 8: // RESOURCE_EXHAUSTED
                    throw AppError.unknown(NSError(domain: "FirebaseFunctions", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                case 13: // INTERNAL
                    // Internal error - check Firebase Console logs for details
                    throw AppError.unknown(NSError(domain: "FirebaseFunctions", code: errorCode, userInfo: [NSLocalizedDescriptionKey: "Firebase Function internal error. Check function logs in Firebase Console. Error: \(errorMessage)"]))
                default:
                    throw AppError.unknown(NSError(domain: "FirebaseFunctions", code: errorCode, userInfo: [NSLocalizedDescriptionKey: "Firebase Function error (code \(errorCode)): \(errorMessage)"]))
                }
            }
            
            // Handle FunctionsError from Firebase SDK (if available)
            // Note: FunctionsError might not be available in all Firebase SDK versions
            
            // Handle network errors
            if error.domain == NSURLErrorDomain {
                throw AppError.networkError(error)
            }
            
            throw AppError.unknown(error)
        }
    }
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }
    
    /// Sign in anonymously (for quick setup)
    func signInAnonymously() async throws {
        _ = try await Auth.auth().signInAnonymously()
    }
}

