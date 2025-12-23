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
            if !isMealTypeManuallySet {
                updateInferredMealType()
            }
        }
    }
    @Published var inferredMealType: MealType
    @Published var selectedMealType: MealType
    @Published var isMealTypeManuallySet: Bool = false
    @Published var selectedDate: Date = Date()
    @Published var showDatePicker: Bool = false
    
    private var isUpdatingFromInference: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var latestResult: MealLogResponse?
    @Published var isListening: Bool = false
    
    private var openAIService: OpenAIService?
    private var openAIServiceError: AppError?
    private var modelContext: ModelContext?
    let speechService = SpeechRecognitionService()
    
    init() {
        // Initialize OpenAI service - handle error gracefully
        do {
            self.openAIService = try OpenAIService()
        } catch {
            // Store error to show when user tries to log a meal
            if let appError = error as? AppError {
                self.openAIServiceError = appError
            } else {
                self.openAIServiceError = AppError.unknown(error)
            }
        }
        
        // Initialize meal type based on IST time on app launch
        let initialMealType = MealTypeInference.inferMealTypeFromISTNow()
        inferredMealType = initialMealType
        selectedMealType = initialMealType
        
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
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func updateInferredMealType() {
        let newType = MealTypeInference.determineMealType(text: foodText)
        if newType != inferredMealType {
            inferredMealType = newType
            
            // Update selected meal type if not manually set
            if !isMealTypeManuallySet {
                isUpdatingFromInference = true
                selectedMealType = newType
                isUpdatingFromInference = false
            }
        }
    }
    
    func setMealType(_ mealType: MealType, isManual: Bool = true) {
        selectedMealType = mealType
        isMealTypeManuallySet = isManual
    }
    
    func handleMealTypeChange(_ newValue: MealType) {
        // Only mark as manual if change didn't come from inference
        if !isUpdatingFromInference {
            setMealType(newValue, isManual: true)
        }
    }
    
    func logMeal() async {
        guard !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Check if OpenAI service is available
        guard let openAIService = openAIService else {
            errorMessage = openAIServiceError?.errorDescription ?? AppError.apiKeyNotFound.errorDescription
            return
        }
        
        isLoading = true
        errorMessage = nil
        latestResult = nil
        
        do {
            let mealTypeString = selectedMealType.rawValue
            let response = try await openAIService.logMeal(foodText: foodText, mealType: mealTypeString)
            
            // Save to SwiftData
            if let context = modelContext {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(response)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                
                // Create entry with selected date and current creation time
                let entry = MealEntry(
                    id: UUID(),
                    timestamp: selectedDate,
                    createdAt: Date(),  // Actual creation time
                    foodText: foodText,
                    mealType: response.mealType,
                    totalCalories: response.totalCalories,
                    rawResponseJson: jsonString
                )
                
                context.insert(entry)
                try context.save()
            }
            
            latestResult = response
            foodText = "" // Clear input after successful log
            isMealTypeManuallySet = false // Reset manual selection
            selectedDate = Date() // Reset to today
            
        } catch {
            if let appError = error as? AppError {
                errorMessage = appError.errorDescription
            } else {
                errorMessage = AppError.unknown(error).errorDescription
            }
        }
        
        isLoading = false
    }
    
    func toggleSpeechRecognition() {
        if speechService.isListening {
            speechService.stopListening()
        } else {
            Task {
                await speechService.startListening()
            }
        }
    }
}

