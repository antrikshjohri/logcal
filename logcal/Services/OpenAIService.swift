//
//  OpenAIService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation

struct OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init() {
        guard let key = Secrets.getAPIKey() else {
            fatalError("OPENAI_API_KEY not found in Secrets.plist")
        }
        self.apiKey = key
        print("DEBUG: OpenAIService initialized with API key")
    }
    
    func logMeal(foodText: String, mealType: String) async throws -> MealLogResponse {
        print("DEBUG: Starting meal log request for: \(foodText), mealType: \(mealType)")
        
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
            "model": "gpt-4o-2024-08-06",
            "temperature": 0.3,
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
        
        guard let url = URL(string: baseURL) else {
            print("DEBUG: Invalid URL")
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("DEBUG: Request body created successfully")
        } catch {
            print("DEBUG: Failed to serialize request body: \(error)")
            throw error
        }
        
        print("DEBUG: Sending request to OpenAI API")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("DEBUG: Invalid HTTP response")
            throw NSError(domain: "OpenAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }
        
        print("DEBUG: Received response with status code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("DEBUG: API error response: \(errorString)")
            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(errorString)"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            print("DEBUG: Failed to parse response JSON")
            throw NSError(domain: "OpenAIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        print("DEBUG: Parsed content from response: \(content)")
        
        guard let contentData = content.data(using: .utf8) else {
            print("DEBUG: Failed to convert content to data")
            throw NSError(domain: "OpenAIService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to convert content to data"])
        }
        
        let decoder = JSONDecoder()
        let mealResponse = try decoder.decode(MealLogResponse.self, from: contentData)
        print("DEBUG: Successfully decoded MealLogResponse")
        
        return mealResponse
    }
}

