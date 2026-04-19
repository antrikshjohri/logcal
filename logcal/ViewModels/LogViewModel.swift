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
    @Published var isRefiningMeal: Bool = false
    @Published var errorMessage: String?
    @Published var latestResult: MealLogResponse?
    /// Set after a successful log so the preview quick-edit can update the same `MealEntry`.
    @Published var lastLoggedMealId: UUID?
    @Published var isListening: Bool = false
    @Published var isTranscribingSpeech: Bool = false
    @Published var waveformSamples: [CGFloat] = Array(repeating: 0.08, count: 64)
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
        
        speechService.onTranscriptionResult = { [weak self] text in
            guard let self else { return }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            if self.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.foodText = trimmed
            } else {
                self.foodText += " " + trimmed
            }
            print("DEBUG: [LogViewModel] Merged Whisper transcript into foodText (len=\(trimmed.count))")
        }

        speechService.$isListening
            .sink { [weak self] isListening in
                self?.isListening = isListening
            }
            .store(in: &cancellables)

        speechService.$isTranscribing
            .sink { [weak self] transcribing in
                self?.isTranscribingSpeech = transcribing
            }
            .store(in: &cancellables)

        speechService.$waveformSamples
            .sink { [weak self] samples in
                self?.waveformSamples = samples
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()

    var canSubmitMeal: Bool {
        isListening || !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
    }
    
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
        
        // Stop recording and wait for Whisper if a dictation is in progress
        if speechService.isListening {
            AnalyticsService.trackSpeechRecognitionStopped()
            await speechService.stopListening()
        }
        await speechService.waitUntilIdle()

        // Allow logging if either text or image is present after any in-flight dictation is merged in.
        let hasText = !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = selectedImage != nil
        
        guard hasText || hasImage else {
            print("DEBUG: Both food text and image are empty after dictation/transcription, returning")
            return
        }
        
        print("DEBUG: hasText: \(hasText), hasImage: \(hasImage)")
        
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
        lastLoggedMealId = nil
        
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
                // #region agent log
                if let debugLogData = try? JSONSerialization.data(withJSONObject: ["location": "LogViewModel.swift:171", "message": "Encoded MealLogResponse to JSON", "data": ["protein": response.protein as Any, "carbs": response.carbs as Any, "fat": response.fat as Any, "jsonStringLength": jsonString.count, "hasProtein": response.protein != nil], "timestamp": Date().timeIntervalSince1970 * 1000, "sessionId": "debug-session", "runId": "run1", "hypothesisId": "B"]), let logString = String(data: debugLogData, encoding: .utf8) {
                    try? (logString + "\n").write(toFile: "/Users/ajohri/Documents/Antriksh Personal/LogCal/logcal/.cursor/debug.log", atomically: false, encoding: .utf8)
                }
                // #endregion
                
                // Determine if image was used and set appropriate foodText
                let hadImage = selectedImage != nil
                let displayText: String
                if foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hadImage {
                    // Image only - use placeholder text
                    displayText = "Image uploaded"
                } else {
                    // Text only or text + image
                    displayText = foodText
                }
                
                // Create entry with selected date and current creation time
                let entry = MealEntry(
                    id: UUID(),
                    timestamp: selectedDate,
                    createdAt: Date(),  // Actual creation time
                    foodText: displayText,
                    mealType: response.mealType,
                    totalCalories: response.totalCalories,
                    rawResponseJson: jsonString,
                    hasImage: hadImage
                )
                
                context.insert(entry)
                try context.save()
                lastLoggedMealId = entry.id
                print("DEBUG: [LogViewModel] lastLoggedMealId=\(entry.id)")
                
                // Sync to Firestore if user is signed in
                Task {
                    await cloudSyncService.syncMealToCloud(entry)
                }
                
                // Reschedule notifications after meal is logged (smart logic will skip if needed)
                Task {
                    await NotificationService.shared.rescheduleNotificationsIfNeeded(modelContext: context)
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
            
            // Increment meal log count for rating service
            RatingService.shared.incrementMealLogCount()
            
            // Check and show rating dialog if appropriate (with delay to let success animation play)
            if RatingService.shared.shouldShowRatingDialog() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    RatingService.shared.requestRating()
                }
            }
            
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
        if speechService.isTranscribing {
            print("DEBUG: [LogViewModel] toggleSpeech ignored while transcribing")
            return
        }
        if speechService.isListening {
            AnalyticsService.trackSpeechRecognitionStopped()
            Task {
                await speechService.stopListening()
            }
        } else {
            AnalyticsService.trackSpeechRecognitionStarted()
            Task {
                await speechService.startListening()
            }
        }
    }

    func stopSpeechRecognition() {
        guard speechService.isListening else { return }
        AnalyticsService.trackSpeechRecognitionStopped()
        Task {
            await speechService.stopListening()
        }
    }
    
    func selectImage(_ image: UIImage?) {
        selectedImage = image
        print("DEBUG: [LogViewModel] Image selected: \(image != nil ? "yes" : "no")")
        if image != nil {
            AnalyticsService.trackImageSelected()
        }
    }
    
    func removeImage() {
        selectedImage = nil
        print("DEBUG: [LogViewModel] Image removed")
    }

    /// Quick-edit the meal shown in the success preview (same row as `latestResult`).
    func quickRefineLoggedMeal(correctionPrompt: String) async {
        guard let id = lastLoggedMealId, let context = modelContext else {
            errorMessage = "Could not find the saved meal to update."
            print("DEBUG: [LogViewModel] quickRefineLoggedMeal missing id or context")
            return
        }
        await appConfigService.fetchConfig()
        if !appConfigService.isAppVersionValid() {
            showUpdateRequiredAlert = true
            return
        }
        guard let openAIService = openAIService else {
            errorMessage = openAIServiceError?.errorDescription ?? AppError.apiKeyNotFound.errorDescription
            return
        }
        let descriptor = FetchDescriptor<MealEntry>(predicate: #Predicate<MealEntry> { $0.id == id })
        guard let entry = try? context.fetch(descriptor).first else {
            errorMessage = "Meal not found."
            print("DEBUG: [LogViewModel] quickRefineLoggedMeal no entry for id=\(id)")
            return
        }
        isRefiningMeal = true
        errorMessage = nil
        defer { isRefiningMeal = false }
        do {
            let refined = try await MealQuickRefine.apply(
                entry: entry,
                correctionPrompt: correctionPrompt,
                modelContext: context,
                openAIService: openAIService,
                cloudSyncService: cloudSyncService
            )
            latestResult = refined
            print("DEBUG: [LogViewModel] quickRefineLoggedMeal success")
        } catch {
            if let appError = error as? AppError {
                errorMessage = appError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
            print("DEBUG: [LogViewModel] quickRefineLoggedMeal error: \(error)")
        }
    }
}
