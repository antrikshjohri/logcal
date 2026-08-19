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
import WidgetKit

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
    @Published var pendingLogs: [PendingMealLog] = []
    @Published var completedPreviews: [CompletedMealPreview] = []
    @Published var isPreviewMode: Bool = false
    @Published var isListening: Bool = false
    @Published var isTranscribingSpeech: Bool = false
    @Published var speechErrorMessage: String?
    @Published var waveformSamples: [CGFloat] = Array(repeating: 0.08, count: 64)
    @Published var selectedImages: [UIImage] = []
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

        speechService.$errorMessage
            .sink { [weak self] message in
                self?.speechErrorMessage = message
            }
            .store(in: &cancellables)
        
        // Listen to application willEnterForeground and day change notifications
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .merge(with: NotificationCenter.default.publisher(for: NSNotification.Name.NSCalendarDayChanged))
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.checkAndResetSelectedDateIfNeeded()
                }
            }
            .store(in: &cancellables)
            
        // Initial setup of last active date
        let now = Date()
        if UserDefaults.standard.object(forKey: "lastActiveDate") == nil {
            UserDefaults.standard.set(now, forKey: "lastActiveDate")
        }
    }
    
    private var cancellables = Set<AnyCancellable>()

    var canSubmitMeal: Bool {
        isListening || !foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    @discardableResult
    func saveLatestMealAsFavorite() -> SavedMeal? {
        guard let result = latestResult,
              let id = lastLoggedMealId,
              let context = modelContext else {
            errorMessage = "Could not save this meal yet."
            return nil
        }

        let descriptor = FetchDescriptor<MealEntry>(predicate: #Predicate<MealEntry> { $0.id == id })
        guard let entry = try? context.fetch(descriptor).first else {
            errorMessage = "Could not find the logged meal to save."
            return nil
        }

        return saveMealEntryAsFavorite(entry, response: result, context: context)
    }

    func logSavedMealAsIs(_ savedMeal: SavedMeal, servingMultiplier: Double = 1.0) {
        guard let context = modelContext else {
            errorMessage = "Could not log favourite meal."
            return
        }

        let response = savedMeal.response?.scaled(by: servingMultiplier)
        let rawResponseJson: String
        if let response,
           let jsonData = try? JSONEncoder().encode(response),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            rawResponseJson = jsonString
        } else {
            rawResponseJson = savedMeal.rawResponseJson
        }

        let totalCalories = response?.totalCalories ?? (savedMeal.totalCalories * servingMultiplier)
        let foodText = servingMultiplier == 1.0
            ? savedMeal.foodText
            : "\(savedMeal.foodText) (\(SavedMealServing.label(for: servingMultiplier)) serving)"

        let entry = MealEntry(
            id: UUID(),
            timestamp: selectedDate,
            createdAt: Date(),
            foodText: foodText,
            mealType: savedMeal.mealType,
            totalCalories: totalCalories,
            rawResponseJson: rawResponseJson,
            hasImage: false,
            sourceSavedMealId: savedMeal.id
        )

        context.insert(entry)
        do {
            try context.save()
            WidgetCenter.shared.reloadAllTimelines()
            lastLoggedMealId = entry.id
            let effectiveResponse = response ?? savedMeal.response
            latestResult = effectiveResponse

            if let effectiveResponse {
                let preview = CompletedMealPreview(
                    id: entry.id,
                    response: effectiveResponse,
                    foodText: foodText,
                    mealType: MealType(rawValue: savedMeal.mealType) ?? .breakfast,
                    date: selectedDate
                )
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    completedPreviews.removeAll { $0.id == entry.id }
                    completedPreviews.insert(preview, at: 0)
                }
            }

            Task { @MainActor in
                await cloudSyncService.syncMealToCloud(entry)
                await HealthKitService.shared.saveMealEntry(entry)
            }
            Task { @MainActor in
                await NotificationService.shared.rescheduleNotificationsIfNeeded(modelContext: context)
            }

            AnalyticsService.trackMealLogged(
                mealType: entry.mealType,
                totalCalories: entry.totalCalories,
                itemCount: response?.items.count ?? savedMeal.response?.items.count ?? 0,
                hasImage: false
            )
            RatingService.shared.incrementMealLogCount()

            self.foodText = ""
            selectedImages = []
            isMealTypeManuallySet = false
        } catch {
            errorMessage = AppError.unknown(error).errorDescription
        }
    }

    func prepareSavedMealForEditing(_ savedMeal: SavedMeal) {
        foodText = savedMeal.foodText
        if let mealType = MealType(rawValue: savedMeal.mealType) {
            setMealType(mealType, isManual: true)
        }
        selectedImages = []
        latestResult = nil
        lastLoggedMealId = nil
    }

    @discardableResult
    private func saveMealEntryAsFavorite(_ entry: MealEntry, response: MealLogResponse, context: ModelContext) -> SavedMeal? {
        let title = SavedMealTitle.suggestedTitle(foodText: entry.foodText, response: response)
        
        let count = (try? context.fetchCount(FetchDescriptor<SavedMeal>())) ?? 0
        let savedMeal = SavedMeal(
            title: title,
            foodText: entry.foodText,
            mealType: entry.mealType,
            totalCalories: entry.totalCalories,
            rawResponseJson: entry.rawResponseJson,
            sourceMealId: entry.id,
            displayOrder: count
        )

        context.insert(savedMeal)
        do {
            entry.sourceSavedMealId = savedMeal.id
            try context.save()
            WidgetCenter.shared.reloadAllTimelines()
            Task { @MainActor in
                await cloudSyncService.syncSavedMealsToCloud(modelContext: context)
            }
            return savedMeal
        } catch {
            errorMessage = AppError.unknown(error).errorDescription
            return nil
        }
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
        let trimmedInput = foodText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasInitialText = !trimmedInput.isEmpty
        let hasInitialImage = !selectedImages.isEmpty
        let isDictating = speechService.isListening

        guard isDictating || hasInitialText || hasInitialImage else {
            print("DEBUG: Both food text and image are empty, returning")
            return
        }

        // Stop recording and wait for Whisper if a dictation is in progress
        if speechService.isListening {
            AnalyticsService.trackSpeechRecognitionStopped()
            await speechService.stopListening()
        }
        await speechService.waitUntilIdle()

        let capturedFoodText = foodText.trimmingCharacters(in: .whitespacesAndNewlines)
        let capturedImages = selectedImages
        let capturedMealType = selectedMealType
        let capturedDate = selectedDate
        let capturedHasText = !capturedFoodText.isEmpty
        let capturedHasImage = !capturedImages.isEmpty

        guard capturedHasText || capturedHasImage else {
            print("DEBUG: Both food text and image are empty after dictation/transcription, returning")
            return
        }

        // Reset composer instantly so user can immediately log another meal
        foodText = ""
        selectedImages = []
        isMealTypeManuallySet = false
        updateInferredMealType()

        let pending = PendingMealLog(
            id: UUID(),
            foodText: capturedFoodText,
            images: capturedImages,
            mealType: capturedMealType,
            selectedDate: capturedDate,
            createdAt: Date(),
            isPreviewOnly: isPreviewMode,
            status: .processing
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            pendingLogs.insert(pending, at: 0)
        }

        // Process in background task
        Task {
            await processPendingMeal(pending)
        }
    }

    func retryPendingMeal(id: UUID) {
        guard let index = pendingLogs.firstIndex(where: { $0.id == id }) else { return }
        var pending = pendingLogs[index]
        pending.status = .processing
        pendingLogs[index] = pending
        Task {
            await processPendingMeal(pending)
        }
    }

    func removePendingMeal(id: UUID) {
        withAnimation(.easeInOut(duration: 0.25)) {
            pendingLogs.removeAll { $0.id == id }
        }
    }

    private func processPendingMeal(_ pending: PendingMealLog) async {
        var perf = PerfLogger("meal_log_queue")
        print("DEBUG: [LogViewModel] Processing pending meal id=\(pending.id) text='\(pending.foodText)' isPreview=\(pending.isPreviewOnly)")

        await appConfigService.fetchConfig()
        if !appConfigService.isAppVersionValid() {
            showUpdateRequiredAlert = true
            updatePendingStatus(id: pending.id, status: .failed(error: "App update required"))
            return
        }

        guard let openAIService = openAIService else {
            let errorMsg = openAIServiceError?.errorDescription ?? AppError.apiKeyNotFound.errorDescription ?? "OpenAI API key not configured."
            updatePendingStatus(id: pending.id, status: .failed(error: errorMsg))
            return
        }

        do {
            let mealTypeString = pending.mealType.rawValue
            let response = try await openAIService.logMeal(
                foodText: pending.foodText,
                mealType: mealTypeString,
                images: pending.images
            )
            perf.mark("ai_meal_response", metadata: [
                "calories": response.totalCalories,
                "itemCount": response.items.count,
            ])

            var savedEntryId = pending.id
            let trimmedText = pending.foodText.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayText: String
            if !trimmedText.isEmpty && trimmedText != "Image uploaded" {
                displayText = trimmedText
            } else if !response.items.isEmpty {
                let itemNames = response.items.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                displayText = itemNames.isEmpty ? "\(response.mealType.capitalized) Meal" : itemNames.joined(separator: ", ")
            } else {
                displayText = "\(response.mealType.capitalized) Meal"
            }

            if !pending.isPreviewOnly, let context = modelContext {
                let jsonEncoder = JSONEncoder()
                let jsonData = try jsonEncoder.encode(response)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

                let entry = MealEntry(
                    id: pending.id,
                    timestamp: pending.selectedDate,
                    createdAt: pending.createdAt,
                    foodText: displayText,
                    mealType: response.mealType,
                    totalCalories: response.totalCalories,
                    rawResponseJson: jsonString,
                    hasImage: !pending.images.isEmpty
                )
                savedEntryId = entry.id

                context.insert(entry)
                try context.save()

                if !pending.images.isEmpty, let firstImage = pending.images.first {
                    ImageUtils.saveMealImageLocally(image: firstImage, forMealId: entry.id)
                }

                WidgetCenter.shared.reloadAllTimelines()
                
                Task { @MainActor in
                    await cloudSyncService.syncMealToCloud(entry)
                    await HealthKitService.shared.saveMealEntry(entry)
                }

                Task { @MainActor in
                    await NotificationService.shared.rescheduleNotificationsIfNeeded(modelContext: context)
                }
            }

            latestResult = response
            if !pending.isPreviewOnly {
                lastLoggedMealId = savedEntryId
            }

            let preview = CompletedMealPreview(
                id: savedEntryId,
                response: response,
                foodText: displayText,
                mealType: pending.mealType,
                date: pending.selectedDate,
                isPreviewOnly: pending.isPreviewOnly
            )

            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                completedPreviews.removeAll { $0.id == savedEntryId }
                completedPreviews.insert(preview, at: 0)
            }

            updatePendingStatus(id: pending.id, status: .completed(response: response, entryId: savedEntryId))

            if !pending.isPreviewOnly {
                AnalyticsService.trackMealLogged(
                    mealType: response.mealType,
                    totalCalories: response.totalCalories,
                    itemCount: response.items.count,
                    hasImage: !pending.images.isEmpty
                )

                RatingService.shared.incrementMealLogCount()
                if RatingService.shared.shouldShowRatingDialog() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        RatingService.shared.requestRating()
                    }
                }
            }

            // Auto-dismiss in-progress tray row once completed
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(.easeInOut(duration: 0.3)) {
                    if let idx = self.pendingLogs.firstIndex(where: { $0.id == pending.id }),
                       case .completed = self.pendingLogs[idx].status {
                        self.pendingLogs.remove(at: idx)
                    }
                }
            }

        } catch {
            print("DEBUG: [LogViewModel] processPendingMeal error: \(error)")
            let errorType = (error as? AppError)?.errorDescription ?? "unknown"
            AnalyticsService.trackMealLogFailed(errorType: errorType)

            let desc: String
            if let appError = error as? AppError {
                desc = appError.errorDescription ?? "Failed to log meal."
            } else {
                desc = error.localizedDescription
            }
            updatePendingStatus(id: pending.id, status: .failed(error: desc))
        }
    }

    func logPreviewMeal(previewId: UUID) {
        guard let index = completedPreviews.firstIndex(where: { $0.id == previewId }) else { return }
        let preview = completedPreviews[index]
        guard let context = modelContext else {
            errorMessage = "Could not access local database."
            return
        }

        let response = preview.response
        let rawJson = (try? JSONEncoder().encode(response)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let entry = MealEntry(
            id: preview.id,
            timestamp: preview.date,
            createdAt: Date(),
            foodText: preview.foodText,
            mealType: preview.mealType.rawValue,
            totalCalories: response.totalCalories,
            rawResponseJson: rawJson,
            hasImage: false
        )

        context.insert(entry)
        do {
            try context.save()
            WidgetCenter.shared.reloadAllTimelines()
            lastLoggedMealId = entry.id
            latestResult = response

            withAnimation(.easeInOut(duration: 0.3)) {
                completedPreviews[index].isPreviewOnly = false
            }

            Task { @MainActor in
                await cloudSyncService.syncMealToCloud(entry)
                await HealthKitService.shared.saveMealEntry(entry)
            }
            Task { @MainActor in
                await NotificationService.shared.rescheduleNotificationsIfNeeded(modelContext: context)
            }
            AnalyticsService.trackMealLogged(
                mealType: entry.mealType,
                totalCalories: entry.totalCalories,
                itemCount: response.items.count,
                hasImage: false
            )
            RatingService.shared.incrementMealLogCount()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            errorMessage = AppError.unknown(error).errorDescription
        }
    }

    func dismissCompletedPreview(id: UUID) {
        withAnimation(.easeOut(duration: 0.3)) {
            completedPreviews.removeAll { $0.id == id }
            if completedPreviews.isEmpty {
                latestResult = nil
                lastLoggedMealId = nil
            } else {
                latestResult = completedPreviews.first?.response
                lastLoggedMealId = completedPreviews.first?.id
            }
        }
    }

    func quickRefineCompletedPreview(id: UUID, correctionPrompt: String) async {
        guard let index = completedPreviews.firstIndex(where: { $0.id == id }) else {
            await quickRefineLoggedMeal(correctionPrompt: correctionPrompt)
            return
        }

        let trimmed = correctionPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await appConfigService.fetchConfig()
        if !appConfigService.isAppVersionValid() {
            showUpdateRequiredAlert = true
            return
        }

        guard let openAIService = openAIService else {
            errorMessage = openAIServiceError?.errorDescription ?? AppError.apiKeyNotFound.errorDescription
            return
        }

        let isPreviewOnly = completedPreviews[index].isPreviewOnly
        completedPreviews[index].isRefining = true
        completedPreviews[index].refineError = nil

        if isPreviewOnly {
            do {
                let refined = try await openAIService.refineMeal(
                    foodText: completedPreviews[index].foodText,
                    mealType: completedPreviews[index].mealType.rawValue,
                    previous: completedPreviews[index].response,
                    correctionPrompt: trimmed
                )
                completedPreviews[index].response = refined
                completedPreviews[index].isRefining = false
                if lastLoggedMealId == id {
                    latestResult = refined
                }
            } catch {
                completedPreviews[index].isRefining = false
                if let appError = error as? AppError {
                    completedPreviews[index].refineError = appError.errorDescription
                } else {
                    completedPreviews[index].refineError = error.localizedDescription
                }
            }
            return
        }

        guard let context = modelContext,
              let entry = try? context.fetch(FetchDescriptor<MealEntry>(predicate: #Predicate<MealEntry> { $0.id == id })).first else {
            errorMessage = "Meal not found."
            completedPreviews[index].isRefining = false
            return
        }

        do {
            let refined = try await MealQuickRefine.apply(
                entry: entry,
                correctionPrompt: trimmed,
                modelContext: context,
                openAIService: openAIService,
                cloudSyncService: cloudSyncService
            )

            completedPreviews[index].response = refined
            completedPreviews[index].isRefining = false
            if lastLoggedMealId == id {
                latestResult = refined
            }
        } catch {
            completedPreviews[index].isRefining = false
            if let appError = error as? AppError {
                completedPreviews[index].refineError = appError.errorDescription
            } else {
                completedPreviews[index].refineError = error.localizedDescription
            }
        }
    }

    func saveCompletedMealAsFavorite(previewId: UUID) -> SavedMeal? {
        guard let context = modelContext,
              let entry = try? context.fetch(FetchDescriptor<MealEntry>(predicate: #Predicate<MealEntry> { $0.id == previewId })).first,
              let preview = completedPreviews.first(where: { $0.id == previewId }) else {
            return saveLatestMealAsFavorite()
        }

        return saveMealEntryAsFavorite(entry, response: preview.response, context: context)
    }

    private func updatePendingStatus(id: UUID, status: PendingLogStatus) {
        guard let index = pendingLogs.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            pendingLogs[index].status = status
        }
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

    func cancelSpeechRecognition() {
        guard speechService.isListening else { return }
        speechService.cancelListening()
    }
    
    func setImages(_ images: [UIImage]) {
        selectedImages = Array(images.prefix(Constants.Images.maxMealImages))
        print("DEBUG: [LogViewModel] Images selected: \(selectedImages.count)")
        if !selectedImages.isEmpty {
            AnalyticsService.trackImageSelected()
        }
    }

    func appendImage(_ image: UIImage?) {
        guard let image else { return }
        guard selectedImages.count < Constants.Images.maxMealImages else {
            errorMessage = "You can add up to \(Constants.Images.maxMealImages) images."
            return
        }
        selectedImages.append(image)
        print("DEBUG: [LogViewModel] Image appended, count=\(selectedImages.count)")
        AnalyticsService.trackImageSelected()
    }
    
    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
        print("DEBUG: [LogViewModel] Image removed, count=\(selectedImages.count)")
    }

    /// Quick-edit the meal shown in the success preview (same row as `latestResult`).
    func quickRefineLoggedMeal(correctionPrompt: String) async {
        guard let id = lastLoggedMealId, let context = modelContext else {
            errorMessage = "Could not find the logged meal to update."
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
    
    func checkAndResetSelectedDateIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        
        let lastActiveDate = UserDefaults.standard.object(forKey: "lastActiveDate") as? Date ?? now
        
        // If the selectedDate matches the lastActiveDate calendar day, it means
        // the user was viewing "today" during the last active session.
        if calendar.isDate(selectedDate, inSameDayAs: lastActiveDate) {
            // If the day has rolled over (selectedDate is not today anymore),
            // reset selectedDate to the new today.
            if !calendar.isDate(selectedDate, inSameDayAs: now) {
                selectedDate = now
            }
        }
        
        // Update the last active date to today
        UserDefaults.standard.set(now, forKey: "lastActiveDate")
    }
}
