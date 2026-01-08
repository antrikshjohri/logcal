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
                print("DEBUG: Anonymous sign-in completed")
            } else {
                print("DEBUG: User already authenticated")
            }
            print("DEBUG: Calling firebaseService.logMeal()...")
            
            // Convert image to Data for Firebase Function
            var imageData: Data? = nil
            if let image = image {
                imageData = image.jpegData(compressionQuality: 0.8)
                print("DEBUG: Image converted to Data: \(imageData?.count ?? 0) bytes")
            }
            
            return try await firebaseService.logMeal(foodText: foodText, mealType: mealType, imageData: imageData)
        }
        
        // Fallback to direct OpenAI API (for development)
        guard let apiKey = apiKey else {
            throw AppError.apiKeyNotFound
        }
        
        return try await logMealDirect(foodText: foodText, mealType: mealType, image: image, apiKey: apiKey)
    }
    
    private func logMealDirect(foodText: String, mealType: String, image: UIImage?, apiKey: String) async throws -> MealLogResponse {
        let systemPrompt = """
        You are a calorie logging assistant. When given a food description or image, estimate calories based on typical portion sizes. Use the provided meal type. Never ask for clarifications - always set needs_clarification to false and clarifying_question to an empty string. Provide detailed breakdowns of items with quantities, calories, assumptions, and confidence scores.
        """
        
        // Build user message content
        var userContent: [[String: Any]] = []
        
        // Add text if provided
        if !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let textMessage = """
            Food description: \(foodText)
            Meal type: \(mealType)
            """
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
            return try decoder.decode(MealLogResponse.self, from: contentData)
        } catch {
            throw AppError.parseError
        }
    }
}

