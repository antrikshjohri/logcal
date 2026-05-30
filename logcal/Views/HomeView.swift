//
//  HomeView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData
import Lottie
import UIKit
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = LogViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    private var userName: String {
        if let name = authViewModel.userName {
            return name
        } else if let email = Auth.auth().currentUser?.email {
            return String(email.split(separator: "@").first ?? "User")
        }
        return "User"
    }
    @EnvironmentObject private var toastManager: ToastManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedMeal.updatedAt, order: .reverse) private var savedMeals: [SavedMeal]
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("navigateToDate") private var navigateToDateTimestamp: Double = 0
    @State private var showConfetti = false
    @State private var mealPreviewAutoDismissWork: DispatchWorkItem?
    @State private var quickEditPrompt = ""
    @State private var selectedSavedMeal: SavedMeal?
    @State private var showAllFavorites = false
    @State private var showMealTypeDropdown = false
    
    var body: some View {
        ZStack {
            NavigationStack {
                mainContent
                    .navigationTitle("Log")
                    .navigationBarTitleDisplayMode(.large)
                    .onChange(of: viewModel.latestResult) { oldValue, newValue in
                        mealPreviewAutoDismissWork?.cancel()
                        mealPreviewAutoDismissWork = nil
                        if newValue == nil {
                            quickEditPrompt = ""
                        }
                        
                        if oldValue == nil && newValue != nil {
                            showConfetti = true
                            // Auto-dismiss confetti after animation completes (3 seconds)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                showConfetti = false
                            }
                        }
                        
                        if newValue != nil {
                            let work = DispatchWorkItem { [viewModel] in
                                print("DEBUG: [HomeView] Meal preview auto-dismiss after 2 minutes")
                                withAnimation(.easeOut(duration: 0.3)) {
                                    viewModel.latestResult = nil
                                }
                            }
                            mealPreviewAutoDismissWork = work
                            DispatchQueue.main.asyncAfter(deadline: .now() + 120.0, execute: work)
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SetMealTypeFromNotification"))) { notification in
                        // Set meal type when notification is tapped
                        if let userInfo = notification.userInfo,
                           let mealTypeString = userInfo["mealType"] as? String,
                           let mealType = MealType(rawValue: mealTypeString) {
                            print("DEBUG: [HomeView] Setting meal type from notification: \(mealTypeString)")
                            viewModel.selectedMealType = mealType
                            viewModel.isMealTypeManuallySet = true
                        }
                    }
                    .modifier(HomeViewModifiers(
                        viewModel: viewModel,
                        modelContext: modelContext,
                        navigateToDateTimestamp: $navigateToDateTimestamp,
                        toastManager: toastManager,
                        showConfetti: $showConfetti,
                        showUpdateRequiredAlert: Binding(
                            get: { viewModel.showUpdateRequiredAlert },
                            set: { viewModel.showUpdateRequiredAlert = $0 }
                        )
                    ))
                    .sheet(item: $selectedSavedMeal) { savedMeal in
                        SavedMealLogSheet(
                            savedMeal: savedMeal,
                            onLog: { servingMultiplier in
                                viewModel.logSavedMealAsIs(savedMeal, servingMultiplier: servingMultiplier)
                                selectedSavedMeal = nil
                            },
                            onEdit: {
                                viewModel.prepareSavedMealForEditing(savedMeal)
                                selectedSavedMeal = nil
                                isTextFieldFocused = true
                            }
                        )
                    }
                    .sheet(isPresented: $showAllFavorites) {
                        AllFavoritesSheet(
                            savedMeals: savedMeals,
                            onSelectMeal: { meal in
                                showAllFavorites = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    selectedSavedMeal = meal
                                }
                            }
                        )
                    }
            }

        }
    }
    
    /// Extra bottom padding so multi-line food text does not scroll under the mic row or listening/transcribing banner.
    private var foodTextEditorBottomPadding: CGFloat {
        let iconRowInset: CGFloat = 55
        let trimmed = viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines)
        let statusBannerAtBottom = !trimmed.isEmpty && (viewModel.isListening || viewModel.isTranscribingSpeech)
        // Subheadline can wrap; keep text above the banner that sits above the icon row (~52pt).
        let bannerInset: CGFloat = statusBannerAtBottom ? 80 : 0
        let total = iconRowInset + bannerInset
        print("DEBUG: [HomeView] foodTextEditorBottomPadding=\(total) banner=\(statusBannerAtBottom)")
        return total
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                Group {
                    Text("What's on your plate, \(userName)?")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                    
                    dateAndMealTypeRow
                    
                    if !savedMeals.isEmpty {
                        savedMealsSection
                    }
                    
                    foodTextInputCard
                    
                    logMealButton
                    
                    resultCardSection
                }
                .frame(maxWidth: horizontalSizeClass == .regular ? 650 : .infinity)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .background(
            Theme.backgroundColor(colorScheme: colorScheme)
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
        .dismissDropdownOnScroll(show: $showMealTypeDropdown)
    }

    private var dateAndMealTypeRow: some View {
        HStack(spacing: 12) {
            // Date picker
            VStack(alignment: .leading, spacing: 6) {
                Text("DATE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                
                HStack(spacing: 0) {
                    // Left arrow - previous day
                    Button(action: {
                        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .frame(width: 28, height: 40)
                            .contentShape(Rectangle())
                    }
                    
                    // Date text - opens calendar sheet
                    Button(action: {
                        AnalyticsService.trackDatePickerOpened()
                        viewModel.showDatePicker = true
                    }) {
                        HStack(spacing: 4) {
                            Text(DateFormatterCache.formatDate(viewModel.selectedDate))
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                .lineLimit(1)
                            Image(systemName: "calendar")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.primaryGreen)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    
                    // Right arrow - next day
                    Button(action: {
                        viewModel.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: viewModel.selectedDate) ?? viewModel.selectedDate
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .frame(width: 28, height: 40)
                            .contentShape(Rectangle())
                    }
                }
                .frame(height: 40)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity)
            
            // Meal type picker
            VStack(alignment: .leading, spacing: 6) {
                Text("MEAL TYPE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                
                HStack(spacing: 0) {
                    // Left arrow - previous meal type (wraps around)
                    Button(action: {
                        let allMeals = MealType.allCases
                        if let idx = allMeals.firstIndex(of: viewModel.selectedMealType) {
                            let prevIdx = (idx - 1 + allMeals.count) % allMeals.count
                            viewModel.selectedMealType = allMeals[prevIdx]
                            viewModel.handleMealTypeChange(viewModel.selectedMealType)
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .frame(width: 28, height: 40)
                            .contentShape(Rectangle())
                    }
                    
                    // Meal type label - taps to toggle custom dropdown
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showMealTypeDropdown.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(viewModel.selectedMealType.rawValue.capitalized)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                .lineLimit(1)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.primaryGreen)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // Right arrow - next meal type (wraps around)
                    Button(action: {
                        let allMeals = MealType.allCases
                        if let idx = allMeals.firstIndex(of: viewModel.selectedMealType) {
                            let nextIdx = (idx + 1) % allMeals.count
                            viewModel.selectedMealType = allMeals[nextIdx]
                            viewModel.handleMealTypeChange(viewModel.selectedMealType)
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .frame(width: 28, height: 40)
                            .contentShape(Rectangle())
                    }
                }
                .frame(height: 40)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            showMealTypeDropdown ? Theme.primaryGreen.opacity(0.5) : Theme.cardBorder(colorScheme: colorScheme),
                            lineWidth: showMealTypeDropdown ? 1.5 : 1
                        )
                )
                .overlay(alignment: .top) {
                    if showMealTypeDropdown {
                        VStack(spacing: 0) {
                            ForEach(Array(MealType.allCases.enumerated()), id: \.element) { index, mealType in
                                Button(action: {
                                    viewModel.selectedMealType = mealType
                                    viewModel.handleMealTypeChange(mealType)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showMealTypeDropdown = false
                                    }
                                }) {
                                    HStack {
                                        Text(mealType.rawValue.capitalized)
                                            .font(.system(size: 14, weight: mealType == viewModel.selectedMealType ? .bold : .medium, design: .rounded))
                                            .foregroundColor(
                                                mealType == viewModel.selectedMealType
                                                ? Theme.primaryGreen
                                                : Theme.primaryText(colorScheme: colorScheme)
                                            )
                                        Spacer()
                                        if mealType == viewModel.selectedMealType {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Theme.primaryGreen)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                if index < MealType.allCases.count - 1 {
                                    Divider()
                                        .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                        .padding(.horizontal, 10)
                                }
                            }
                        }
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                        )
                        .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.8), radius: 12, x: 0, y: 6)
                        .background {
                            Color.black.opacity(0.001)
                                .contentShape(Rectangle())
                                .frame(width: 2000, height: 2000)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showMealTypeDropdown = false
                                    }
                                }
                        }
                        .offset(y: 44)
                        .zIndex(100)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .zIndex(showMealTypeDropdown ? 10 : 0)
        }
        .padding(.horizontal)
        .zIndex(showMealTypeDropdown ? 100 : 0)
        .sheet(isPresented: $viewModel.showDatePicker) {
            LogDatePickerSheet(
                selectedDate: $viewModel.selectedDate,
                isPresented: $viewModel.showDatePicker
            )
        }
    }

    private var foodTextInputCard: some View {
        let isComposerBusy = viewModel.isListening || viewModel.isTranscribingSpeech
        let imageLimitReached = viewModel.selectedImages.count >= Constants.Images.maxMealImages
        
        return VStack(alignment: .leading, spacing: 10) {
            Text("What did you eat?")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.foodText)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 80)
                        .focused($isTextFieldFocused)
                        .allowsHitTesting(!viewModel.isListening && !viewModel.isTranscribingSpeech)
                    
                    let isTextEmpty = viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    let showPlaceholder = isTextEmpty && viewModel.selectedImages.isEmpty
                        && !viewModel.isListening && !viewModel.isTranscribingSpeech
                    
                    if showPlaceholder {
                        Text("Write or speak naturally about what you ate...")
                            .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                            .font(.system(size: 16, design: .rounded))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                if !viewModel.selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                                        )
                                    
                                    Button(action: {
                                        AnalyticsService.trackImageRemoved()
                                        viewModel.removeImage(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                    }
                }
                
                Divider()
                    .background(Theme.cardBorder(colorScheme: colorScheme))
                    .padding(.horizontal, 12)
                
                HStack(alignment: .center, spacing: 8) {
                    if viewModel.isListening {
                        // --- Recording mode ---
                        Button(action: {
                            viewModel.cancelSpeechRecognition()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.red.opacity(0.85))
                                .clipShape(Circle())
                        }
                        
                        inlineWaveformVisualizer
                        
                        Button(action: {
                            viewModel.stopSpeechRecognition()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Theme.primaryGreen)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            isTextFieldFocused = false
                            Task {
                                await viewModel.logMeal()
                            }
                        }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    } else {
                        // --- Normal mode ---
                        HStack(spacing: 10) {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button(action: {
                                    AnalyticsService.trackCameraPickerOpened()
                                    viewModel.showCameraPicker = true
                                }) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.primaryGreen)
                                        .padding(10)
                                        .background(Theme.softAccentBackground(colorScheme: colorScheme))
                                        .clipShape(Circle())
                                }
                                .disabled(isComposerBusy || imageLimitReached)
                                .opacity((isComposerBusy || imageLimitReached) ? 0.45 : 1)
                            }
                            
                            Button(action: {
                                AnalyticsService.trackImagePickerOpened()
                                viewModel.showImagePicker = true
                            }) {
                                Image(systemName: !viewModel.selectedImages.isEmpty ? "photo.fill" : "photo")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.primaryGreen)
                                    .padding(10)
                                    .background(Theme.softAccentBackground(colorScheme: colorScheme))
                                    .clipShape(Circle())
                            }
                            .disabled(isComposerBusy || imageLimitReached)
                            .opacity((isComposerBusy || imageLimitReached) ? 0.45 : 1)
                        }
                        
                        Spacer()
                        
                        if viewModel.isTranscribingSpeech {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Transcribing...")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            }
                            .padding(.trailing, 8)
                        }
                        
                        Button(action: {
                            isTextFieldFocused = false
                            viewModel.toggleSpeechRecognition()
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Color.orange.opacity(0.35), radius: 6, x: 0, y: 3)
                        }
                        .disabled(viewModel.isTranscribingSpeech)
                        .opacity(viewModel.isTranscribingSpeech ? 0.45 : 1)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .animation(.easeInOut(duration: 0.25), value: viewModel.isListening)
            }
            .background(Theme.cardBackground(colorScheme: colorScheme))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
            )
            .shadow(color: Theme.shadowColor(colorScheme: colorScheme), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePickerView(selectedImages: Binding(
                get: { viewModel.selectedImages },
                set: { viewModel.setImages($0) }
            ))
        }
        .sheet(isPresented: $viewModel.showCameraPicker) {
            CameraPickerView(selectedImage: Binding(
                get: { nil },
                set: { viewModel.appendImage($0) }
            ))
        }
    }

    private var logMealButton: some View {
        let canSubmitMeal = viewModel.canSubmitMeal
        return Button(action: {
            isTextFieldFocused = false
            Task {
                print("DEBUG: Log Meal button tapped")
                await viewModel.logMeal()
                print("DEBUG: Log Meal button action completed")
            }
        }) {
            ZStack {
                if viewModel.isLoading {
                    LottieView(animationName: "LoadingAnimation", loopMode: LottieLoopMode.loop, contentMode: .scaleAspectFit)
                        .frame(height: 24)
                } else {
                    Text("Log Meal")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                viewModel.isLoading
                    ? Color.gray.opacity(0.3)
                    : (canSubmitMeal
                        ? Theme.primaryGreen
                        : Theme.primaryGreen.opacity(0.12))
            )
            .foregroundColor(canSubmitMeal && !viewModel.isLoading ? .white : Theme.primaryGreen.opacity(0.4))
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        canSubmitMeal || viewModel.isLoading ? Color.clear : Theme.primaryGreen.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(color: canSubmitMeal && !viewModel.isLoading ? Theme.primaryGreen.opacity(0.3) : Color.clear, radius: 6, x: 0, y: 3)
        }
        .disabled(!canSubmitMeal || viewModel.isLoading || viewModel.isTranscribingSpeech)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var resultCardSection: some View {
        if let result = viewModel.latestResult {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 0) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Logged Successfully")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        
                        Text(result.mealType.capitalized)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.softAccentBackground(colorScheme: colorScheme))
                            .foregroundColor(Theme.primaryGreen)
                            .cornerRadius(6)
                    }
                    
                    Spacer(minLength: 12)
                    
                    Button(action: {
                        viewModel.saveLatestMealAsFavorite()
                        toastManager.show(ToastMessage(
                            title: "Saved",
                            message: "Meal added to favourites.",
                            type: .success
                        ))
                    }) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.primaryGreen)
                            .accessibilityLabel("Save meal")
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 16)

                    Button(action: {
                        print("DEBUG: [HomeView] User dismissed meal preview (close)")
                        mealPreviewAutoDismissWork?.cancel()
                        mealPreviewAutoDismissWork = nil
                        quickEditPrompt = ""
                        viewModel.errorMessage = nil
                        withAnimation(.easeOut(duration: 0.3)) {
                            viewModel.latestResult = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Dismiss meal summary")
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(result.totalCalories)) cal")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                }
                
                // Macros Row
                if let macros = result.resolvedMealMacrosForDisplay() {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.proteinColor)
                                .frame(width: 8, height: 8)
                            Text("\(Int(macros.protein))g Protein")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.proteinColor.opacity(0.12))
                        .cornerRadius(12)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.carbsColor)
                                .frame(width: 8, height: 8)
                            Text("\(Int(macros.carbs))g Carbs")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.carbsColor.opacity(0.12))
                        .cornerRadius(12)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.fatColor)
                                .frame(width: 8, height: 8)
                            Text("\(Int(macros.fat))g Fat")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.fatColor.opacity(0.12))
                        .cornerRadius(12)
                    }
                    .padding(.top, 4)
                }
                
                Divider()
                    .background(Theme.cardBorder(colorScheme: colorScheme))
                
                Text("Items Breakdown")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                
                ForEach(Array(result.items.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            Spacer()
                            Text("\(Int(item.calories)) cal")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryGreen)
                        }
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        
                        if let p = item.protein, let c = item.carbs, let f = item.fat {
                            MacrosCaptionLine(protein: p, carbs: c, fat: f, font: .system(size: 11, design: .rounded))
                                .padding(.top, 2)
                        }
                        
                        if let assumptions = item.assumptions, !assumptions.isEmpty {
                            Text("Assumptions: \(assumptions)")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if index < result.items.count - 1 {
                        Divider()
                            .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                            .padding(.horizontal, 10)
                    }
                }

                Divider()
                    .background(Theme.cardBorder(colorScheme: colorScheme))
                
                QuickEditMealSection(
                    prompt: $quickEditPrompt,
                    isLoading: viewModel.isRefiningMeal,
                    errorMessage: viewModel.errorMessage
                ) {
                    Task {
                        let text = quickEditPrompt
                        await viewModel.quickRefineLoggedMeal(correctionPrompt: text)
                        if viewModel.errorMessage == nil {
                            quickEditPrompt = ""
                        }
                    }
                }
            }
            .padding(16)
            .background(Theme.cardBackground(colorScheme: colorScheme))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
            )
            .padding(.horizontal)
            .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.5), radius: 6, x: 0, y: 3)
            .onAppear {
                AnalyticsService.trackMealSummaryViewed()
            }
        }
    }

    private var savedMealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Favourites")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                
                Spacer()
                
                if !savedMeals.isEmpty {
                    Button(action: {
                        showAllFavorites = true
                    }) {
                        Text("See all")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.primaryGreen)
                    }
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(savedMeals.prefix(8)) { savedMeal in
                        Button {
                            selectedSavedMeal = savedMeal
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.primaryGreen)

                                Text(savedMeal.title.count > 40 ? String(savedMeal.title.prefix(40)) + "..." : savedMeal.title)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                    .lineLimit(1)

                                Text("\(Int(savedMeal.totalCalories)) cal")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(19)
                            .overlay(
                                RoundedRectangle(cornerRadius: 19)
                                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                            .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var inlineWaveformVisualizer: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 3
            let barWidth: CGFloat = 3
            let samples = viewModel.waveformSamples
            let capacity = max(1, Int((geometry.size.width + spacing) / (barWidth + spacing)))
            let visible = Array(samples.suffix(capacity))
            let visibleSamples = if visible.count == capacity {
                visible
            } else {
                Array(repeating: 0.08, count: capacity - visible.count) + visible
            }
            
            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(visibleSamples.enumerated()), id: \.offset) { index, sample in
                    let height = max(4, 32 * sample)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange,
                                    Color.orange.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: barWidth, height: height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
    }
}

/// Sheet showing all saved meals with search and a link to manage them.
private struct AllFavoritesSheet: View {
    let savedMeals: [SavedMeal]
    let onSelectMeal: (SavedMeal) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    
    private var filteredMeals: [SavedMeal] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return Array(savedMeals)
        }
        return savedMeals.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredMeals.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(filteredMeals) { meal in
                        Button {
                            onSelectMeal(meal)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.primaryGreen)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(meal.title)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                        .lineLimit(1)
                                    
                                    if let response = meal.response {
                                        Text(response.items.prefix(3).map(\.name).joined(separator: ", "))
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("\(Int(meal.totalCalories)) cal")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section {
                    NavigationLink(destination: SavedMealsView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.primaryGreen)
                            Text("Manage Favourites")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.primaryGreen)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search favourites")
            .navigationTitle("Favourites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Graphical date picker: dismisses as soon as the user taps a **different** calendar day (one tap). "Close" still available if they only browse months.
private struct LogDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var dayBaselineForDismiss: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundColor(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .tint(Theme.primaryGreen)
                        .padding(8)
                    }
                    .background(Theme.cardBackground(colorScheme: colorScheme))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                    )
                    .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.4), radius: 8, x: 0, y: 4)
                    .padding(16)
                    
                    Spacer()
                }
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        print("DEBUG: [LogDatePickerSheet] Close tapped")
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryGreen)
                }
            }
            .onAppear {
                dayBaselineForDismiss = selectedDate
                print("DEBUG: [LogDatePickerSheet] opened baseline day=\(selectedDate)")
            }
            .onChange(of: selectedDate) { _, newValue in
                guard let baseline = dayBaselineForDismiss else { return }
                if !Calendar.current.isDate(newValue, equalTo: baseline, toGranularity: .day) {
                    print("DEBUG: [LogDatePickerSheet] new day selected, dismissing")
                    isPresented = false
                }
            }
        }
    }
}

private struct SavedMealLogSheet: View {
    let savedMeal: SavedMeal
    let onLog: (Double) -> Void
    let onEdit: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var servingMultiplier = 1.0
    @State private var isRenaming = false
    @State private var renameText = ""

    private var scaledResponse: MealLogResponse? {
        savedMeal.response?.scaled(by: servingMultiplier)
    }

    private var displayedCalories: Double {
        scaledResponse?.totalCalories ?? savedMeal.totalCalories * servingMultiplier
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    HStack(alignment: .firstTextBaseline, spacing: Constants.Spacing.small) {
                        Text(savedMeal.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            renameText = savedMeal.title
                            isRenaming = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Theme.primaryGreen)
                                .frame(width: 32, height: 32)
                        }
                        .accessibilityLabel("Rename favourite meal")
                    }

                    Text("\(Int(displayedCalories)) cal · \(savedMeal.mealType.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    let p = (savedMeal.protein ?? 0) * servingMultiplier
                    let c = (savedMeal.carbs ?? 0) * servingMultiplier
                    let f = (savedMeal.fat ?? 0) * servingMultiplier
                    if p > 0 || c > 0 || f > 0 {
                        Text("Protein: \(Int(p))g  ·  Carbs: \(Int(c))g  ·  Fat: \(Int(f))g")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    Text("Serving")
                        .font(.headline)

                    Picker("Serving", selection: $servingMultiplier) {
                        ForEach(SavedMealServing.commonMultipliers, id: \.self) { multiplier in
                            Text(SavedMealServing.label(for: multiplier)).tag(multiplier)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let response = scaledResponse ?? savedMeal.response {
                    VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                        Text("Items")
                            .font(.headline)

                        ForEach(Array(response.items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .fontWeight(.medium)
                                    Text(item.quantity)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(Int(item.calories)) cal")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                Button {
                    onLog(servingMultiplier)
                    dismiss()
                } label: {
                    Text("Log")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.primaryGreen)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.Sizes.cornerRadius)
                }

                Button {
                    onEdit()
                    dismiss()
                } label: {
                    Text("Edit before logging")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Constants.Colors.primaryBackground)
                        .foregroundColor(Theme.primaryGreen)
                        .cornerRadius(Constants.Sizes.cornerRadius)
                }
            }
            .padding()
            .navigationTitle("Favourite Meal")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Rename Favourite Meal", isPresented: $isRenaming) {
                TextField("Name", text: $renameText)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    renameSavedMeal()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func renameSavedMeal() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        savedMeal.title = String(trimmed.prefix(140))
        savedMeal.updatedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - View Modifiers
struct HomeViewModifiers: ViewModifier {
    let viewModel: LogViewModel
    let modelContext: ModelContext
    @Binding var navigateToDateTimestamp: Double
    let toastManager: ToastManager
    @Binding var showConfetti: Bool
    @Binding var showUpdateRequiredAlert: Bool
    
    func body(content: Content) -> some View {
        content
            .modifier(HomeViewAppearModifier(viewModel: viewModel, modelContext: modelContext))
            .modifier(HomeViewChangeModifiers(
                viewModel: viewModel,
                navigateToDateTimestamp: $navigateToDateTimestamp,
                toastManager: toastManager,
                showConfetti: $showConfetti
            ))
            .modifier(HomeViewAlertModifier(
                viewModel: viewModel,
                showUpdateRequiredAlert: $showUpdateRequiredAlert
            ))
            .modifier(HomeViewOverlayModifier(showConfetti: $showConfetti))
    }
}

struct HomeViewAppearModifier: ViewModifier {
    let viewModel: LogViewModel
    let modelContext: ModelContext
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .scrollDismissesKeyboard(.interactively)
    }
}

struct HomeViewChangeModifiers: ViewModifier {
    let viewModel: LogViewModel
    @Binding var navigateToDateTimestamp: Double
    let toastManager: ToastManager
    @Binding var showConfetti: Bool
    
    func body(content: Content) -> some View {
        content
            .modifier(NavigateToDateModifier(viewModel: viewModel, navigateToDateTimestamp: $navigateToDateTimestamp))
            .modifier(ErrorMessageModifier(viewModel: viewModel, toastManager: toastManager))
            .modifier(SpeechErrorModifier(viewModel: viewModel, toastManager: toastManager))
    }
}

struct NavigateToDateModifier: ViewModifier {
    let viewModel: LogViewModel
    @Binding var navigateToDateTimestamp: Double
    
    func body(content: Content) -> some View {
        content
            .onChange(of: navigateToDateTimestamp) { oldValue, newValue in
                if newValue > 0 && newValue != oldValue {
                    let date = Date(timeIntervalSince1970: newValue)
                    viewModel.selectedDate = date
                    navigateToDateTimestamp = 0
                }
            }
    }
}

struct ErrorMessageModifier: ViewModifier {
    let viewModel: LogViewModel
    let toastManager: ToastManager
    
    func body(content: Content) -> some View {
        content
            .onReceive(viewModel.$errorMessage) { message in
                if let message {
                    toastManager.show(ToastMessage(
                        title: "Error",
                        message: message,
                        type: .error
                    ))
                }
            }
    }
}

private struct DictationWaveformView: View {
    let samples: [CGFloat]

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 3
            let barWidth: CGFloat = 3
            let visibleSamples = displayedSamples(for: geometry.size.width, barWidth: barWidth, spacing: spacing)

            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(visibleSamples.enumerated()), id: \.offset) { index, sample in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index, count: visibleSamples.count))
                        .frame(width: barWidth, height: max(6, 28 * sample))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 36)
    }

    private func displayedSamples(for availableWidth: CGFloat, barWidth: CGFloat, spacing: CGFloat) -> [CGFloat] {
        let capacity = max(1, Int((availableWidth + spacing) / (barWidth + spacing)))
        let visible = Array(samples.suffix(capacity))
        if visible.count == capacity {
            return visible
        }
        return Array(repeating: 0.08, count: capacity - visible.count) + visible
    }

    private func barColor(for index: Int, count: Int) -> Color {
        index > count / 2
            ? Theme.primaryGreen.opacity(0.55)
            : Theme.primaryGreen.opacity(0.9)
    }
}

struct SpeechErrorModifier: ViewModifier {
    let viewModel: LogViewModel
    let toastManager: ToastManager
    
    func body(content: Content) -> some View {
        content
            .onReceive(viewModel.$speechErrorMessage) { message in
                if let message {
                    toastManager.show(ToastMessage(
                        title: "Dictation Error",
                        message: message,
                        type: .warning
                    ))
                }
            }
    }
}

struct HomeViewAlertModifier: ViewModifier {
    let viewModel: LogViewModel
    @Binding var showUpdateRequiredAlert: Bool
    
    func body(content: Content) -> some View {
        content
            .alert("Update Required", isPresented: $showUpdateRequiredAlert) {
                Button("Update Now") {
                    if let appStoreURL = viewModel.appConfigService.getAppStoreURL() {
                        UIApplication.shared.open(appStoreURL)
                    }
                }
                Button("Later", role: .cancel) { }
            } message: {
                Text(viewModel.appConfigService.appConfig.updateMessage ?? "A new version of LogCal is available. Please update to continue logging meals.")
            }
    }
}

struct HomeViewOverlayModifier: ViewModifier {
    @Binding var showConfetti: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if showConfetti {
                LottieView(animationName: "ConfettiAnimation", loopMode: LottieLoopMode.playOnce, contentMode: .scaleAspectFit)
                    .frame(width: 400, height: 400)
                    .allowsHitTesting(false)
                    .zIndex(1000)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [MealEntry.self, SavedMeal.self])
}

extension View {
    @ViewBuilder
    func dismissDropdownOnScroll(show: Binding<Bool>) -> some View {
        if #available(iOS 18.0, *) {
            self.onScrollPhaseChange { _, newPhase in
                if newPhase != .idle && show.wrappedValue {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        show.wrappedValue = false
                    }
                }
            }
        } else {
            self
        }
    }
}

