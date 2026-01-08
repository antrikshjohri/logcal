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
import UIKit

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
    @Published var selectedImage: UIImage?
    @Published var showImagePicker: Bool = false
    @Published var showCameraPicker: Bool = false
    
    private var openAIService: OpenAIService?
    private var openAIServiceError: AppError?
    private var modelContext: ModelContext?
    private let cloudSyncService = CloudSyncService()
    let speechService = SpeechRecognitionService()
    let appConfigService = AppConfigService()
    @Published var showUpdateRequiredAlert = false
    
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
            // Track analytics - meal type changed manually
            AnalyticsService.trackMealTypeChanged(mealType: newValue.rawValue)
        }
    }
    
    func logMeal() async {
        print("DEBUG: logMeal() called")
        print("DEBUG: foodText: '\(foodText)'")
        print("DEBUG: selectedMealType: \(selectedMealType.rawValue)")
        print("DEBUG: Constants.API.useFirebase: \(Constants.API.useFirebase)")
        
        // Allow logging if either text or image is present
        let hasText = !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = selectedImage != nil
        
        guard hasText || hasImage else {
            print("DEBUG: Both food text and image are empty, returning")
            return
        }
        
        print("DEBUG: hasText: \(hasText), hasImage: \(hasImage)")
        
        // Stop speech recognition immediately when Log Meal button is tapped
        if speechService.isListening {
            speechService.stopListening()
        }
        
        // Check app version before proceeding
        await appConfigService.fetchConfig()
        if !appConfigService.isAppVersionValid() {
            print("DEBUG: App version is outdated. Current: \(AppConfigService.currentMarketingVersion), Required: \(appConfigService.appConfig.minimumAppVersion)")
            showUpdateRequiredAlert = true
            return
        }
        
        // Check if OpenAI service is available
        guard let openAIService = openAIService else {
            print("DEBUG: OpenAI service is nil, error: \(openAIServiceError?.errorDescription ?? "unknown")")
            errorMessage = openAIServiceError?.errorDescription ?? AppError.apiKeyNotFound.errorDescription
            return
        }
        
        print("DEBUG: OpenAI service is available, proceeding...")
        isLoading = true
        errorMessage = nil
        latestResult = nil
        
        do {
            let mealTypeString = selectedMealType.rawValue
            print("DEBUG: Calling openAIService.logMeal()...")
            let response = try await openAIService.logMeal(foodText: foodText, mealType: mealTypeString, image: selectedImage)
            print("DEBUG: Received response from openAIService: \(response.totalCalories) calories")
            
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
                
                // Sync to Firestore if user is signed in
                Task {
                    await cloudSyncService.syncMealToCloud(entry)
                }
            }
            
            latestResult = response
            
            // Track analytics - successful meal log (check image before clearing)
            let hadImage = selectedImage != nil
            AnalyticsService.trackMealLogged(
                mealType: response.mealType,
                totalCalories: response.totalCalories,
                itemCount: response.items.count,
                hasImage: hadImage
            )
            
            foodText = "" // Clear input after successful log
            selectedImage = nil // Clear image after successful log
            isMealTypeManuallySet = false // Reset manual selection
            selectedDate = Date() // Reset to today
            
        } catch {
            print("DEBUG: Error caught in logMeal(): \(error)")
            print("DEBUG: Error type: \(type(of: error))")
            print("DEBUG: Error localizedDescription: \(error.localizedDescription)")
            
            // Track analytics - failed meal log
            let errorType = (error as? AppError)?.errorDescription ?? "unknown"
            AnalyticsService.trackMealLogFailed(errorType: errorType)
            
            if let appError = error as? AppError {
                print("DEBUG: It's an AppError: \(appError.errorDescription ?? "no description")")
                errorMessage = appError.errorDescription
            } else {
                print("DEBUG: It's an unknown error, wrapping in AppError")
                errorMessage = AppError.unknown(error).errorDescription
            }
        }
        
        isLoading = false
        print("DEBUG: logMeal() completed, isLoading = false")
    }
    
    func toggleSpeechRecognition() {
        if speechService.isListening {
            speechService.stopListening()
            // Track analytics
            AnalyticsService.trackSpeechRecognitionStopped()
        } else {
            // Track analytics
            AnalyticsService.trackSpeechRecognitionStarted()
            Task {
                await speechService.startListening()
            }
        }
    }
    
    func selectImage(_ image: UIImage?) {
        selectedImage = image
        print("DEBUG: [LogViewModel] Image selected: \(image != nil ? "yes" : "no")")
    }
    
    func removeImage() {
        selectedImage = nil
        print("DEBUG: [LogViewModel] Image removed")
    }
}

