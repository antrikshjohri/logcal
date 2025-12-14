//
//  LogViewModel.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class LogViewModel: ObservableObject {
    @Published var foodText: String = "" {
        didSet {
            updateInferredMealType()
        }
    }
    @Published var inferredMealType: MealType = .snack
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var latestResult: MealLogResponse?
    @Published var isListening: Bool = false
    
    private let openAIService = OpenAIService()
    private var modelContext: ModelContext?
    let speechService = SpeechRecognitionService()
    
    init() {
        // Update foodText when speech recognition updates (only when actively listening)
        speechService.$recognizedText
            .combineLatest(speechService.$isListening)
            .sink { [weak self] text, isListening in
                if isListening {
                    self?.foodText = text
                }
            }
            .store(in: &cancellables)
        
        // Mirror isListening state to published property for SwiftUI observation
        speechService.$isListening
            .sink { [weak self] isListening in
                self?.isListening = isListening
                print("DEBUG: isListening state updated to: \(isListening)")
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        print("DEBUG: LogViewModel model context set")
    }
    
    private func updateInferredMealType() {
        let newType = MealTypeInference.determineMealType(text: foodText)
        if newType != inferredMealType {
            inferredMealType = newType
            print("DEBUG: Updated inferred meal type to: \(newType.rawValue)")
        }
    }
    
    func logMeal() async {
        guard !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("DEBUG: Cannot log meal - food text is empty")
            return
        }
        
        isLoading = true
        errorMessage = nil
        latestResult = nil
        
        print("DEBUG: Starting meal log for: \(foodText)")
        
        do {
            let mealTypeString = inferredMealType.rawValue
            let response = try await openAIService.logMeal(foodText: foodText, mealType: mealTypeString)
            
            print("DEBUG: Received response: \(response.totalCalories) calories")
            
            // Save to SwiftData
            if let context = modelContext {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(response)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                
                let entry = MealEntry(
                    foodText: foodText,
                    mealType: response.mealType,
                    totalCalories: response.totalCalories,
                    rawResponseJson: jsonString
                )
                
                context.insert(entry)
                try context.save()
                print("DEBUG: Saved meal entry to SwiftData")
            }
            
            latestResult = response
            foodText = "" // Clear input after successful log
            
        } catch {
            print("DEBUG: Error logging meal: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func toggleSpeechRecognition() {
        if speechService.isListening {
            speechService.stopListening()
            print("DEBUG: Speech recognition stopped by user")
        } else {
            Task {
                await speechService.startListening()
            }
        }
    }
}

