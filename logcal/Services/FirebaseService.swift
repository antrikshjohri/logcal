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
    private let functions = Functions.functions(region: "asia-southeast1")

    private func makeNetworkStyleError(_ message: String) -> AppError {
        AppError.networkError(NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [
            NSLocalizedDescriptionKey: message,
        ]))
    }

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
                : "Request timed out. Check your connection and try again."
            return speechStyle
                ? .speechRecognitionError(m)
                : makeNetworkStyleError(m)
        case .unavailable:
            return speechStyle
                ? .speechRecognitionError("Service busy. Please try again in a moment.")
                : makeNetworkStyleError("No internet connection. Please check your connection and try again.")
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

    private func logBackendPerf(_ value: Any?, fallbackLabel: String) {
        guard let perf = value as? [String: Any] else { return }
        let label = perf["label"] as? String ?? fallbackLabel
        if let totalMs = perf["totalMs"] {
            print("PERF [backend_\(label)] returned totalMs=\(totalMs)")
        }
        guard let marks = perf["marks"] as? [[String: Any]] else { return }
        for mark in marks {
            let stage = mark["stage"] as? String ?? "unknown"
            let deltaMs = mark["deltaMs"] ?? "?"
            let totalMs = mark["totalMs"] ?? "?"
            var message = "PERF [backend_\(label)] \(stage) +\(deltaMs)ms total=\(totalMs)ms"
            if let metadata = mark["metadata"] as? [String: Any], !metadata.isEmpty {
                let details = metadata
                    .map { "\($0.key)=\($0.value)" }
                    .sorted()
                    .joined(separator: " ")
                message += " \(details)"
            }
            print(message)
        }
    }
    
    /// Transcribe meal dictation audio via Whisper (Firebase callable `transcribeAudio`).
    /// Pass `language` as ISO 639-1 (e.g. `en`, `hi`) or `nil` to use `Constants.Dictation` / auto.
    func transcribeAudio(audioData: Data, mimeType: String = "audio/m4a", language: String? = nil) async throws -> String {
        var perf = PerfLogger("firebase_transcribe_audio")
        if !isAuthenticated {
            print("DEBUG: [FirebaseService] transcribeAudio: signing in anonymously")
            try await signInAnonymously()
            perf.mark("anonymous_sign_in")
        } else {
            perf.mark("already_authenticated")
        }

        let base64String = audioData.base64EncodedString()
        perf.mark("audio_base64_encoded", metadata: [
            "base64Chars": base64String.count,
            "bytes": audioData.count,
        ])
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
            perf.mark("callable_response")
            guard let dict = result.data as? [String: Any],
                  let text = dict["text"] as? String else {
                print("DEBUG: [FirebaseService] transcribeAudio unexpected response: \(String(describing: result.data))")
                perf.end("parse_failed")
                throw AppError.parseError
            }
            logBackendPerf(dict["_perf"], fallbackLabel: "transcribeAudio")
            perf.end("success", metadata: [
                "chars": text.count,
            ])
            return text
        } catch {
            let ns = error as NSError
            print("DEBUG: [FirebaseService] transcribeAudio catch type=\(type(of: error)) domain=\(ns.domain) code=\(ns.code) desc=\(error.localizedDescription) userInfo=\(ns.userInfo)")
            perf.end("failure", metadata: [
                "code": ns.code,
                "domain": ns.domain,
            ])
            throw mapCallableError(ns, speechStyle: true)
        }
    }

    /// Normalize callable dictionary and decode `MealLogResponse` (shared by logMeal / refineMealLog).
    private func decodeMealLogResponse(from dataDict: [String: Any]) throws -> MealLogResponse {
        var normalizedDict = dataDict
        if let needsClarification = normalizedDict["needs_clarification"] {
            if let num = needsClarification as? NSNumber {
                normalizedDict["needs_clarification"] = num.boolValue
            } else if let intVal = needsClarification as? Int {
                normalizedDict["needs_clarification"] = (intVal != 0)
            }
        }
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
        let jsonData = try JSONSerialization.data(withJSONObject: normalizedDict, options: [])
        let decoder = JSONDecoder()
        return try decoder.decode(MealLogResponse.self, from: jsonData).withMealMacrosAlignedToItems()
    }
    
    /// Log a meal using Firebase Functions (requires authentication)
    func logMeal(foodText: String, mealType: String, imageData: Data?) async throws -> MealLogResponse {
        var perf = PerfLogger("firebase_log_meal")
        // Ensure user is authenticated (Firebase Functions onCall handles auth automatically)
        if !isAuthenticated {
            print("DEBUG: User not authenticated, attempting anonymous sign-in...")
            try await signInAnonymously()
            perf.mark("anonymous_sign_in")
            print("DEBUG: Anonymous sign-in successful")
        } else {
            perf.mark("already_authenticated")
        }
        
        // Get user's country from AppStorage
        let userCountry = UserDefaults.standard.string(forKey: "userCountry") ?? ""
        let countryName = getCountryName(for: userCountry)
        perf.mark("country_loaded", metadata: [
            "country": countryName.isEmpty ? "none" : countryName,
        ])
        
        // Prepare request data
        var requestData: [String: Any] = [
            "foodText": foodText,
            "mealType": mealType
        ]
        
        // Add image if provided (convert to base64)
        if let imageData = imageData {
            let base64String = imageData.base64EncodedString()
            requestData["imageBase64"] = base64String
            perf.mark("image_base64_encoded", metadata: [
                "base64Chars": base64String.count,
                "bytes": imageData.count,
            ])
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
            perf.mark("callable_response")
            
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
                perf.end("parse_failed")
                throw AppError.parseError
            }
            logBackendPerf(dataDict["_perf"], fallbackLabel: "logMeal")
            
            let decoded = try decodeMealLogResponse(from: dataDict)
            perf.mark("response_decoded", metadata: [
                "calories": decoded.totalCalories,
                "items": decoded.items.count,
            ])
            print("DEBUG: Successfully decoded MealLogResponse: \(decoded.totalCalories) calories (meal macros aligned to items when possible)")
            // #region agent log
            if let debugLogData = try? JSONSerialization.data(withJSONObject: ["location": "FirebaseService.swift:108", "message": "Decoded MealLogResponse macros", "data": ["protein": decoded.protein as Any, "carbs": decoded.carbs as Any, "fat": decoded.fat as Any, "totalCalories": decoded.totalCalories], "timestamp": Date().timeIntervalSince1970 * 1000, "sessionId": "debug-session", "runId": "run1", "hypothesisId": "A"]), let logString = String(data: debugLogData, encoding: .utf8) {
                try? (logString + "\n").write(toFile: "/Users/ajohri/Documents/Antriksh Personal/LogCal/logcal/.cursor/debug.log", atomically: false, encoding: .utf8)
            }
            // #endregion
            perf.end("success")
            return decoded
        } catch {
            let ns = error as NSError
            print("DEBUG: [FirebaseService] logMeal catch domain=\(ns.domain) code=\(ns.code) desc=\(error.localizedDescription) userInfo=\(ns.userInfo)")
            perf.end("failure", metadata: [
                "code": ns.code,
                "domain": ns.domain,
            ])
            throw mapCallableError(ns, speechStyle: false)
        }
    }

    /// Records non-critical analytics after the meal result is already visible to the user.
    func recordMealLogAnalytics(foodText: String, mealType: String, totalCalories: Double, hasImage: Bool) async {
        var perf = PerfLogger("firebase_record_meal_analytics")
        guard isAuthenticated else {
            print("DEBUG: [FirebaseService] recordMealLogAnalytics skipped: not authenticated")
            perf.end("not_authenticated")
            return
        }

        let requestData: [String: Any] = [
            "foodText": foodText,
            "mealType": mealType,
            "totalCalories": totalCalories,
            "hasImage": hasImage,
        ]

        let function = functions.httpsCallable("recordMealLogAnalytics")
        do {
            let result = try await function.call(requestData)
            perf.mark("callable_response")
            if let dict = result.data as? [String: Any] {
                logBackendPerf(dict["_perf"], fallbackLabel: "recordMealLogAnalytics")
            }
            perf.end("success")
        } catch {
            let ns = error as NSError
            print("DEBUG: [FirebaseService] recordMealLogAnalytics failed domain=\(ns.domain) code=\(ns.code) desc=\(error.localizedDescription)")
            perf.end("failure", metadata: [
                "code": ns.code,
                "domain": ns.domain,
            ])
        }
    }

    /// Refine a saved meal estimate using a user correction (callable `refineMealLog`).
    func refineMealLog(
        foodText: String,
        mealType: String,
        previousResponse: MealLogResponse,
        correctionPrompt: String
    ) async throws -> MealLogResponse {
        if !isAuthenticated {
            print("DEBUG: [FirebaseService] refineMealLog: signing in anonymously")
            try await signInAnonymously()
        }

        let userCountry = UserDefaults.standard.string(forKey: "userCountry") ?? ""
        let countryName = getCountryName(for: userCountry)

        let encoder = JSONEncoder()
        let prevData = try encoder.encode(previousResponse)
        guard let previousObject = try JSONSerialization.jsonObject(with: prevData) as? [String: Any] else {
            print("DEBUG: [FirebaseService] refineMealLog: could not serialize previous estimate")
            throw AppError.parseError
        }

        var requestData: [String: Any] = [
            "foodText": foodText,
            "mealType": mealType,
            "correctionPrompt": correctionPrompt,
            "previousEstimate": previousObject,
        ]
        if !countryName.isEmpty {
            requestData["country"] = countryName
        }

        print("DEBUG: [FirebaseService] refineMealLog callable mealType=\(mealType) correctionLen=\(correctionPrompt.count)")

        let function = functions.httpsCallable("refineMealLog")

        do {
            let result = try await function.call(requestData)
            guard let dataDict = result.data as? [String: Any] else {
                print("DEBUG: [FirebaseService] refineMealLog unexpected response: \(String(describing: result.data))")
                throw AppError.parseError
            }
            let decoded = try decodeMealLogResponse(from: dataDict)
            print("DEBUG: [FirebaseService] refineMealLog decoded \(decoded.totalCalories) cal")
            return decoded
        } catch {
            let ns = error as NSError
            print("DEBUG: [FirebaseService] refineMealLog catch domain=\(ns.domain) code=\(ns.code)")
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
