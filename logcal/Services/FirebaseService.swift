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

    /// Maps Firebase Callable errors using `FunctionsErrorCode` (raw values differ from legacy numeric guesses).
    private func mapCallableError(_ error: NSError, speechStyle: Bool) -> AppError {
        let msg = (error.userInfo[NSLocalizedDescriptionKey] as? String) ?? error.localizedDescription
        print("DEBUG: [FirebaseService] mapCallableError speechStyle=\(speechStyle) domain=\(error.domain) code=\(error.code) msg=\(msg)")

        if error.domain == NSURLErrorDomain {
            return .networkError(error)
        }

        guard error.domain == FunctionsErrorDomain || error.domain == "FIRFunctionsErrorDomain" else {
            return .unknown(error)
        }

        guard let fnCode = FunctionsErrorCode(rawValue: error.code) else {
            print("DEBUG: [FirebaseService] Unknown Functions error raw code=\(error.code)")
            return speechStyle ? .speechRecognitionError(msg) : .unknown(error)
        }

        switch fnCode {
        case .unauthenticated:
            return .permissionDenied("Authentication required")
        case .resourceExhausted:
            return speechStyle ? .speechRecognitionError(msg) : .unknown(error)
        case .invalidArgument:
            return speechStyle ? .speechRecognitionError(msg) : .unknown(NSError(domain: "FirebaseFunctions", code: error.code, userInfo: [NSLocalizedDescriptionKey: msg]))
        case .deadlineExceeded:
            let m = speechStyle
                ? "Transcription timed out. Try a shorter clip or check your connection."
                : msg
            return speechStyle ? .speechRecognitionError(m) : .unknown(NSError(domain: "FirebaseFunctions", code: error.code, userInfo: [NSLocalizedDescriptionKey: m]))
        case .unavailable:
            return speechStyle
                ? .speechRecognitionError("Service busy. Please try again in a moment.")
                : .unknown(error)
        case .internal:
            return speechStyle
                ? .speechRecognitionError(msg.isEmpty ? "Transcription failed. Try again." : msg)
                : .unknown(NSError(domain: "FirebaseFunctions", code: error.code, userInfo: [NSLocalizedDescriptionKey: "Firebase Function error: \(msg)"]))
        case .cancelled:
            return speechStyle ? .speechRecognitionError("Request was cancelled.") : .unknown(error)
        default:
            return speechStyle ? .speechRecognitionError(msg) : .unknown(NSError(domain: "FirebaseFunctions", code: error.code, userInfo: [NSLocalizedDescriptionKey: msg]))
        }
    }
    
    /// Transcribe meal dictation audio via Whisper (Firebase callable `transcribeAudio`).
    /// Pass `language` as ISO 639-1 (e.g. `en`, `hi`) or `nil` to use `Constants.Dictation` / auto.
    func transcribeAudio(audioData: Data, mimeType: String = "audio/m4a", language: String? = nil) async throws -> String {
        if !isAuthenticated {
            print("DEBUG: [FirebaseService] transcribeAudio: signing in anonymously")
            try await signInAnonymously()
        }

        let base64String = audioData.base64EncodedString()
        var requestData: [String: Any] = [
            "audioBase64": base64String,
            "mimeType": mimeType,
        ]
        let lang = language ?? Constants.Dictation.resolvedWhisperLanguageCode()
        if let lang {
            requestData["language"] = lang
        }

        print("DEBUG: [FirebaseService] transcribeAudio callable bytes=\(audioData.count) mime=\(mimeType) language=\(lang ?? "auto")")

        let function = functions.httpsCallable("transcribeAudio")
        function.timeoutInterval = 180

        do {
            let result = try await function.call(requestData)
            guard let dict = result.data as? [String: Any],
                  let text = dict["text"] as? String else {
                print("DEBUG: [FirebaseService] transcribeAudio unexpected response: \(String(describing: result.data))")
                throw AppError.parseError
            }
            return text
        } catch {
            let ns = error as NSError
            print("DEBUG: [FirebaseService] transcribeAudio catch type=\(type(of: error)) domain=\(ns.domain) code=\(ns.code) desc=\(error.localizedDescription) userInfo=\(ns.userInfo)")
            throw mapCallableError(ns, speechStyle: true)
        }
    }

    /// Log a meal using Firebase Functions (requires authentication)
    func logMeal(foodText: String, mealType: String, imageData: Data?) async throws -> MealLogResponse {
        // Ensure user is authenticated (Firebase Functions onCall handles auth automatically)
        if !isAuthenticated {
            print("DEBUG: User not authenticated, attempting anonymous sign-in...")
            try await signInAnonymously()
            print("DEBUG: Anonymous sign-in successful")
        }
        
        // Get user's country from AppStorage
        let userCountry = UserDefaults.standard.string(forKey: "userCountry") ?? ""
        let countryName = getCountryName(for: userCountry)
        
        // Prepare request data
        var requestData: [String: Any] = [
            "foodText": foodText,
            "mealType": mealType
        ]
        
        // Add image if provided (convert to base64)
        if let imageData = imageData {
            let base64String = imageData.base64EncodedString()
            requestData["imageBase64"] = base64String
            print("DEBUG: [FirebaseService] Image added to request, base64 length: \(base64String.count)")
        }
        
        // Add country if available
        if !countryName.isEmpty {
            requestData["country"] = countryName
        }
        
        // Call Firebase Function (onCall automatically includes auth token)
        let function = functions.httpsCallable("logMeal")
        
        do {
            // Log the request being sent to Firebase Function
            if let requestJSON = try? JSONSerialization.data(withJSONObject: requestData, options: .prettyPrinted),
               let requestString = String(data: requestJSON, encoding: .utf8) {
                print("DEBUG: [OpenAI Request] Sending to Firebase Function 'logMeal':")
                print(requestString)
            } else {
                print("DEBUG: [OpenAI Request] Sending to Firebase Function 'logMeal': \(requestData)")
            }
            
            let result = try await function.call(requestData)
            
            // Log the response from Firebase Function
            print("DEBUG: [OpenAI Response] Received from Firebase Function:")
            print("DEBUG: [OpenAI Response] Response type: \(type(of: result.data))")
            // #region agent log
            if let dataDict = result.data as? [String: Any] {
                if let debugLogData = try? JSONSerialization.data(withJSONObject: ["location": "FirebaseService.swift:59", "message": "Raw Firebase Function response", "data": ["hasProtein": dataDict["protein"] != nil, "hasCarbs": dataDict["carbs"] != nil, "hasFat": dataDict["fat"] != nil, "proteinValue": dataDict["protein"] as Any, "carbsValue": dataDict["carbs"] as Any, "fatValue": dataDict["fat"] as Any, "totalCalories": dataDict["total_calories"] as Any], "timestamp": Date().timeIntervalSince1970 * 1000, "sessionId": "debug-session", "runId": "run1", "hypothesisId": "A"]), let logString = String(data: debugLogData, encoding: .utf8) {
                    try? (logString + "\n").write(toFile: "/Users/ajohri/Documents/Antriksh Personal/LogCal/logcal/.cursor/debug.log", atomically: false, encoding: .utf8)
                }
            }
            // #endregion
            if let responseJSON = try? JSONSerialization.data(withJSONObject: result.data, options: .prettyPrinted),
               let responseString = String(data: responseJSON, encoding: .utf8) {
                print("DEBUG: [OpenAI Response] Response data:")
                print(responseString)
            } else {
                print("DEBUG: [OpenAI Response] Response data: \(result.data)")
            }
            
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
            // #region agent log
            if let debugLogData = try? JSONSerialization.data(withJSONObject: ["location": "FirebaseService.swift:108", "message": "Decoded MealLogResponse macros", "data": ["protein": decoded.protein as Any, "carbs": decoded.carbs as Any, "fat": decoded.fat as Any, "totalCalories": decoded.totalCalories], "timestamp": Date().timeIntervalSince1970 * 1000, "sessionId": "debug-session", "runId": "run1", "hypothesisId": "A"]), let logString = String(data: debugLogData, encoding: .utf8) {
                try? (logString + "\n").write(toFile: "/Users/ajohri/Documents/Antriksh Personal/LogCal/logcal/.cursor/debug.log", atomically: false, encoding: .utf8)
            }
            // #endregion
            return decoded
        } catch {
            let ns = error as NSError
            print("DEBUG: [FirebaseService] logMeal catch domain=\(ns.domain) code=\(ns.code) desc=\(error.localizedDescription) userInfo=\(ns.userInfo)")
            throw mapCallableError(ns, speechStyle: false)
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
    
    /// Get country name from country code
    private func getCountryName(for code: String) -> String {
        guard !code.isEmpty else { return "" }
        return Locale.current.localizedString(forRegionCode: code) ?? ""
    }
}

