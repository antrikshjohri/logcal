//
//  OpenAIService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation

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
    
    func logMeal(foodText: String, mealType: String) async throws -> MealLogResponse {
        print("DEBUG: OpenAIService.logMeal() called")
        print("DEBUG: useFirebase = \(Constants.API.useFirebase)")
        
        // Use Firebase Functions if enabled
        if Constants.API.useFirebase {
            print("DEBUG: Using Firebase Functions path")
            // Ensure user is authenticated
            if !firebaseService.isAuthenticated {
                print("DEBUG: User not authenticated, signing in anonymously...")
                // Try anonymous sign-in
                try await firebaseService.signInAnonymously()
                print("DEBUG: Anonymous sign-in completed")
            } else {
                print("DEBUG: User already authenticated")
            }
            print("DEBUG: Calling firebaseService.logMeal()...")
            return try await firebaseService.logMeal(foodText: foodText, mealType: mealType)
        }
        
        // Fallback to direct OpenAI API (for development)
        guard let apiKey = apiKey else {
            throw AppError.apiKeyNotFound
        }
        
        return try await logMealDirect(foodText: foodText, mealType: mealType, apiKey: apiKey)
    }
    
    private func logMealDirect(foodText: String, mealType: String, apiKey: String) async throws -> MealLogResponse {
        let systemPrompt = """
        You are a calorie logging assistant for Indian food. When given a food description, estimate calories based on typical Indian portion sizes. Use the provided meal type. Never ask for clarifications - always set needs_clarification to false and clarifying_question to an empty string. Provide detailed breakdowns of items with quantities, calories, assumptions, and confidence scores.
        """
        
        let userMessage = """
        Food description: \(foodText)
        Meal type: \(mealType)
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
                    "items": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "additionalProperties": false,
                            "properties": [
                                "name": ["type": "string"],
                                "quantity": ["type": "string"],
                                "calories": ["type": "number"],
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
                    "content": userMessage
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
        } catch {
            throw AppError.unknown(error)
        }
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AppError.networkError(error)
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
            return try decoder.decode(MealLogResponse.self, from: contentData)
        } catch {
            throw AppError.parseError
        }
    }
}

