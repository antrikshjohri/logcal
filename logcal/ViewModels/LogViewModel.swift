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
    
    private let openAIService = OpenAIService()
    private var modelContext: ModelContext?
    let speechService = SpeechRecognitionService()
    
    init() {
        // Initialize meal type based on IST time on app launch
        let initialMealType = MealTypeInference.inferMealTypeFromISTNow()
        inferredMealType = initialMealType
        selectedMealType = initialMealType
        print("DEBUG: Initialized meal type on app launch: \(initialMealType.rawValue)")
        
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
        print("DEBUG: Meal type set to: \(mealType.rawValue), manual: \(isManual)")
    }
    
    func handleMealTypeChange(_ newValue: MealType) {
        // Only mark as manual if change didn't come from inference
        if !isUpdatingFromInference {
            setMealType(newValue, isManual: true)
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
            let mealTypeString = selectedMealType.rawValue
            let response = try await openAIService.logMeal(foodText: foodText, mealType: mealTypeString)
            
            print("DEBUG: Received response: \(response.totalCalories) calories")
            
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
                print("DEBUG: Saved meal entry to SwiftData with date: \(selectedDate)")
            }
            
            latestResult = response
            foodText = "" // Clear input after successful log
            isMealTypeManuallySet = false // Reset manual selection
            selectedDate = Date() // Reset to today
            
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

