//
//  OpenAIService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import UIKit

struct OpenAIService {
    private let apiKey: String?
    private let firebaseService = FirebaseService()
    
    init() throws {
        // Only load API key if not using Firebase
        if Constants.API.useFirebase {
            self.apiKey = nil
        } else {
            self.apiKey = try Secrets.getAPIKey()
        }
    }
    
    func logMeal(foodText: String, mealType: String, image: UIImage?) async throws -> MealLogResponse {
        var perf = PerfLogger("openai_service_log_meal")
        print("DEBUG: OpenAIService.logMeal() called")
        print("DEBUG: useFirebase = \(Constants.API.useFirebase)")
        print("DEBUG: hasImage = \(image != nil)")
        
        // Use Firebase Functions if enabled
        if Constants.API.useFirebase {
            print("DEBUG: Using Firebase Functions path")
            // Ensure user is authenticated (sign in anonymously only if not already signed in)
            if !firebaseService.isAuthenticated {
                print("DEBUG: User not authenticated, signing in anonymously...")
                // Try anonymous sign-in (fallback if user skipped auth)
                try await firebaseService.signInAnonymously()
                perf.mark("anonymous_sign_in")
                print("DEBUG: Anonymous sign-in completed")
            } else {
                print("DEBUG: User already authenticated")
                perf.mark("already_authenticated")
            }
            print("DEBUG: Calling firebaseService.logMeal()...")
            
            // Convert image to Data for Firebase Function
            var imageData: Data? = nil
            if let image = image {
                imageData = image.jpegData(compressionQuality: 0.8)
                perf.mark("image_jpeg_encoded", metadata: [
                    "bytes": imageData?.count ?? 0,
                ])
                print("DEBUG: Image converted to Data: \(imageData?.count ?? 0) bytes")
            }
            
            let response = try await firebaseService.logMeal(foodText: foodText, mealType: mealType, imageData: imageData)
            perf.end("firebase_log_meal_complete", metadata: [
                "calories": response.totalCalories,
                "items": response.items.count,
            ])
            return response
        }
        
        // Fallback to direct OpenAI API (for development)
        guard let apiKey = apiKey else {
            throw AppError.apiKeyNotFound
        }
        
        let response = try await logMealDirect(foodText: foodText, mealType: mealType, image: image, apiKey: apiKey)
        perf.end("direct_log_meal_complete", metadata: [
            "calories": response.totalCalories,
            "items": response.items.count,
        ])
        return response
    }

    func recordMealLogAnalytics(foodText: String, mealType: String, totalCalories: Double, hasImage: Bool) async {
        guard Constants.API.useFirebase else { return }
        await firebaseService.recordMealLogAnalytics(
            foodText: foodText,
            mealType: mealType,
            totalCalories: totalCalories,
            hasImage: hasImage
        )
    }

    /// Re-estimate from user correction (uses `refineMealLog` when Firebase is enabled).
    func refineMeal(foodText: String, mealType: String, previous: MealLogResponse, correctionPrompt: String) async throws -> MealLogResponse {
        print("DEBUG: OpenAIService.refineMeal useFirebase=\(Constants.API.useFirebase)")
        if Constants.API.useFirebase {
            if !firebaseService.isAuthenticated {
                try await firebaseService.signInAnonymously()
            }
            return try await firebaseService.refineMealLog(
                foodText: foodText,
                mealType: mealType,
                previousResponse: previous,
                correctionPrompt: correctionPrompt
            )
        }
        guard let apiKey = apiKey else {
            throw AppError.apiKeyNotFound
        }
        return try await refineMealDirect(
            foodText: foodText,
            mealType: mealType,
            previous: previous,
            correctionPrompt: correctionPrompt,
            apiKey: apiKey
        )
    }
    
    private func logMealDirect(foodText: String, mealType: String, image: UIImage?, apiKey: String) async throws -> MealLogResponse {
        let systemPrompt = """
        You are a calorie logging assistant. When given a food description or image, estimate calories and macronutrients (protein, carbs, fat in grams) based on typical portion sizes. Use the provided meal type. Never ask for clarifications - always set needs_clarification to false and clarifying_question to an empty string. Provide detailed breakdowns of items with quantities, calories, macronutrients, assumptions, and confidence scores. The top-level protein, carbs, and fat must equal the sum of the same fields across all items (in grams). When both a written description and a photo are provided, use both together: identify foods and portions from the photo and use the text for context; if they disagree on something visible in the image, trust the image. When a photo is present, each item's assumptions should mention what you inferred from the photo (e.g. visible portion, condiments), not only text-based guesses.
        """
        
        // Build user message content
        var userContent: [[String: Any]] = []
        
        // Add text if provided
        if !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            var textMessage = """
        Food description: \(foodText)
        Meal type: \(mealType)
        """
            if image != nil {
                textMessage += "\nA photo of this meal is attached in this message; combine it with the description above for estimates and assumptions."
            }
            userContent.append([
                "type": "text",
                "text": textMessage
            ])
        } else {
            // If no text, still include meal type
            userContent.append([
                "type": "text",
                "text": "Meal type: \(mealType)"
            ])
        }
        
        // Add image if provided
        if let image = image {
            guard let base64Image = ImageUtils.convertToBase64(image) else {
                throw AppError.unknown(NSError(domain: "ImageUtils", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to base64"]))
            }
            
            userContent.append([
                "type": "image_url",
                "image_url": [
                    "url": base64Image
                ]
            ])
            print("DEBUG: [OpenAI] Image added to request, base64 length: \(base64Image.count)")
        }
        
        let jsonSchema: [String: Any] = [
            "name": "meal_log",
            "schema": [
                "type": "object",
                "additionalProperties": false,
                "properties": [
                    "meal_type": [
                        "type": "string",
                        "enum": ["breakfast", "lunch", "dinner", "snack"]
                    ],
                    "total_calories": ["type": "number"],
                    "protein": ["type": "number"],
                    "carbs": ["type": "number"],
                    "fat": ["type": "number"],
                    "items": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "additionalProperties": false,
                            "properties": [
                                "name": ["type": "string"],
                                "quantity": ["type": "string"],
                                "calories": ["type": "number"],
                                "protein": ["type": "number"],
                                "carbs": ["type": "number"],
                                "fat": ["type": "number"],
                                "assumptions": ["type": "string"],
                                "confidence": ["type": "number"]
                            ],
                            "required": ["name", "quantity", "calories", "confidence"]
                        ]
                    ],
                    "needs_clarification": ["type": "boolean"],
                    "clarifying_question": ["type": "string"]
                ],
                "required": ["meal_type", "total_calories", "items", "needs_clarification"]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": Constants.API.model,
            "temperature": Constants.API.temperature,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userContent
                ]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": jsonSchema
            ]
        ]
        
        guard let url = URL(string: Constants.API.baseURL) else {
            throw AppError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Log the request being sent to OpenAI API
            if let requestJSON = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted),
               let requestString = String(data: requestJSON, encoding: .utf8) {
                print("DEBUG: [OpenAI Request] Sending to OpenAI API:")
                print(requestString)
            } else {
                print("DEBUG: [OpenAI Request] Sending to OpenAI API: \(requestBody)")
            }
        } catch {
            throw AppError.unknown(error)
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AppError.networkError(error)
        }
        
        // Log the raw response from OpenAI API
        if let responseString = String(data: data, encoding: .utf8) {
            print("DEBUG: [OpenAI Response] Received from OpenAI API:")
            print(responseString)
        } else {
            print("DEBUG: [OpenAI Response] Received from OpenAI API (unable to decode as string)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidHTTPResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.apiError(statusCode: httpResponse.statusCode, message: errorString)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AppError.parseError
        }
        
        guard let contentData = content.data(using: .utf8) else {
            throw AppError.dataConversionError
        }
        
        do {
            let decoder = JSONDecoder()
            let parsed = try decoder.decode(MealLogResponse.self, from: contentData)
            return parsed.withMealMacrosAlignedToItems()
        } catch {
            throw AppError.parseError
        }
    }

    private func refineMealDirect(
        foodText: String,
        mealType: String,
        previous: MealLogResponse,
        correctionPrompt: String,
        apiKey: String
    ) async throws -> MealLogResponse {
        let systemPrompt = """
        You are a calorie logging assistant. The user already has a structured meal estimate and wants to correct it. Apply their instructions: fix wrong foods, portions, cooking method, or macros. Output a complete new meal_log JSON. Set needs_clarification to false and clarifying_question to an empty string. Top-level protein, carbs, and fat must equal the sum of the same fields across all items (grams).
        """

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let prevData = try encoder.encode(previous)
        let prevString = String(data: prevData, encoding: .utf8) ?? "{}"
        let desc = foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "(none or image-only log)"
            : foodText
        let userText = """
        Original user description (for context):
        \(desc)

        Meal type: \(mealType)

        Current structured estimate (JSON):
        \(prevString)

        User correction (apply these changes):
        \(correctionPrompt)
        """

        let jsonSchema: [String: Any] = [
            "name": "meal_log",
            "schema": [
                "type": "object",
                "additionalProperties": false,
                "properties": [
                    "meal_type": [
                        "type": "string",
                        "enum": ["breakfast", "lunch", "dinner", "snack"]
                    ],
                    "total_calories": ["type": "number"],
                    "protein": ["type": "number"],
                    "carbs": ["type": "number"],
                    "fat": ["type": "number"],
                    "items": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "additionalProperties": false,
                            "properties": [
                                "name": ["type": "string"],
                                "quantity": ["type": "string"],
                                "calories": ["type": "number"],
                                "protein": ["type": "number"],
                                "carbs": ["type": "number"],
                                "fat": ["type": "number"],
                                "assumptions": ["type": "string"],
                                "confidence": ["type": "number"]
                            ],
                            "required": ["name", "quantity", "calories", "confidence"]
                        ]
                    ],
                    "needs_clarification": ["type": "boolean"],
                    "clarifying_question": ["type": "string"]
                ],
                "required": ["meal_type", "total_calories", "items", "needs_clarification"]
            ]
        ]

        let requestBody: [String: Any] = [
            "model": Constants.API.model,
            "temperature": 0.25,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userText]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": jsonSchema
            ]
        ]

        guard let url = URL(string: Constants.API.baseURL) else {
            throw AppError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("DEBUG: [OpenAI] refineMealDirect userText length=\(userText.count)")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidHTTPResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.apiError(statusCode: httpResponse.statusCode, message: errorString)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8) else {
            throw AppError.parseError
        }
        let decoder = JSONDecoder()
        let parsed = try decoder.decode(MealLogResponse.self, from: contentData)
        return parsed.withMealMacrosAlignedToItems()
    }
}
