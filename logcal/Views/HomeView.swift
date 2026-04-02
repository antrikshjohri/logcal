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

struct HomeView: View {
    @StateObject private var viewModel = LogViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var toastManager: ToastManager
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isTextFieldFocused: Bool
    @AppStorage("navigateToDate") private var navigateToDateTimestamp: Double = 0
    @State private var showConfetti = false
    @State private var mealPreviewAutoDismissWork: DispatchWorkItem?
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Log Calories")
                .onChange(of: viewModel.latestResult) { oldValue, newValue in
                    mealPreviewAutoDismissWork?.cancel()
                    mealPreviewAutoDismissWork = nil
                    
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
                VStack(spacing: 20) {
                    // Welcome message (if signed in)
                    if authViewModel.isSignedIn, let userName = authViewModel.userName {
                        HStack {
                            Text("Welcome \(userName)")
                                .font(.headline)
                                .foregroundColor(Constants.Colors.primaryBlue)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, Constants.Spacing.small)
                    }
                    // Date and Meal Type in same line
                    HStack(spacing: 16) {
                        // Date picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.headline)
                            
                            Button(action: {
                                AnalyticsService.trackDatePickerOpened()
                                viewModel.showDatePicker = true
                            }) {
                                HStack {
                                    Text(DateFormatterCache.formatDate(viewModel.selectedDate))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "calendar")
                                        .foregroundColor(Constants.Colors.primaryBlue)
                                }
                                .frame(height: 44)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity)
                                .background(Constants.Colors.primaryBackground)
                                .cornerRadius(Constants.Sizes.cornerRadius)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Meal type picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal Type")
                                .font(.headline)
                            
                            Picker("Meal Type", selection: $viewModel.selectedMealType) {
                                ForEach(MealType.allCases, id: \.self) { mealType in
                                    Text(mealType.rawValue.capitalized).tag(mealType)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: viewModel.selectedMealType) { oldValue, newValue in
                                viewModel.handleMealTypeChange(newValue)
                            }
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                            .background(Constants.Colors.primaryBackground)
                            .cornerRadius(Constants.Sizes.cornerRadius)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $viewModel.showDatePicker) {
                        LogDatePickerSheet(
                            selectedDate: $viewModel.selectedDate,
                            isPresented: $viewModel.showDatePicker
                        )
                    }
                    
                    // Food text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What did you eat?")
                            .font(.headline)
                        
                        // Image preview (if image is selected)
                        if let image = viewModel.selectedImage {
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius))
                                    
                                    Button(action: {
                                        AnalyticsService.trackImageRemoved()
                                        viewModel.removeImage()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                            .padding(.bottom, Constants.Spacing.small)
                        }
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $viewModel.foodText)
                                .frame(minHeight: Constants.Sizes.textEditorMinHeight)
                                .padding(EdgeInsets(
                                    top: Constants.Spacing.medium,
                                    leading: Constants.Spacing.medium,
                                    bottom: foodTextEditorBottomPadding,
                                    trailing: Constants.Spacing.medium
                                ))
                                .focused($isTextFieldFocused)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                        .stroke(Constants.Colors.borderGray, lineWidth: Constants.Sizes.borderWidth)
                                )

                            let isTextEmpty = viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            let showPlaceholder = isTextEmpty && viewModel.selectedImage == nil
                                && !viewModel.isListening && !viewModel.isTranscribingSpeech

                            if showPlaceholder {
                                Text("Write or speak naturally about what you ate.")
                                    .foregroundColor(Constants.Colors.primaryGray)
                                    .font(.subheadline)
                                    .padding(.horizontal, Constants.Spacing.regular)
                                    .padding(.vertical, Constants.Spacing.large)
                                    .allowsHitTesting(false)
                            }

                            if viewModel.isListening {
                                HStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Constants.Colors.primaryBlue)
                                            .frame(width: 6, height: 6)
                                            .opacity(0.4)
                                            .animation(
                                                Animation.easeInOut(duration: 0.6)
                                                    .repeatForever(autoreverses: true)
                                                    .delay(0.0),
                                                value: viewModel.isListening
                                            )
                                        Circle()
                                            .fill(Constants.Colors.primaryBlue)
                                            .frame(width: 6, height: 6)
                                            .opacity(0.6)
                                            .animation(
                                                Animation.easeInOut(duration: 0.6)
                                                    .repeatForever(autoreverses: true)
                                                    .delay(0.2),
                                                value: viewModel.isListening
                                            )
                                        Circle()
                                            .fill(Constants.Colors.primaryBlue)
                                            .frame(width: 6, height: 6)
                                            .opacity(0.8)
                                            .animation(
                                                Animation.easeInOut(duration: 0.6)
                                                    .repeatForever(autoreverses: true)
                                                    .delay(0.4),
                                                value: viewModel.isListening
                                            )
                                    }
                                    Text("Speak now — tap the mic again when you're done")
                                        .foregroundColor(Constants.Colors.primaryGray)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.horizontal, Constants.Spacing.regular)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isTextEmpty ? .topLeading : .bottomLeading)
                                .padding(.top, isTextEmpty ? Constants.Spacing.large : 0)
                                .padding(.bottom, isTextEmpty ? 0 : 52)
                                .allowsHitTesting(false)
                            } else if viewModel.isTranscribingSpeech {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("Transcribing…")
                                        .foregroundColor(Constants.Colors.primaryGray)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, Constants.Spacing.regular)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isTextEmpty ? .topLeading : .bottomLeading)
                                .padding(.top, isTextEmpty ? Constants.Spacing.large : 0)
                                .padding(.bottom, isTextEmpty ? 0 : 52)
                                .allowsHitTesting(false)
                            }

                            // Icon buttons row (overlaid at bottom, inside text editor boundary)
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()

                                    // Camera button (only show if camera is available)
                                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        Button(action: {
                                            AnalyticsService.trackCameraPickerOpened()
                                            viewModel.showCameraPicker = true
                                        }) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: Constants.Sizes.micIcon))
                                                .foregroundColor(Constants.Colors.primaryBlue)
                                                .padding(Constants.Spacing.medium)
                                                .background(Constants.Colors.micInactiveBackground)
                                                .clipShape(Circle())
                                        }
                                        .padding(.trailing, Constants.Spacing.small)
                                        .padding(.bottom, Constants.Spacing.medium)
                                    }

                                    // Image picker button
                                    Button(action: {
                                        AnalyticsService.trackImagePickerOpened()
                                        viewModel.showImagePicker = true
                                    }) {
                                        Image(systemName: viewModel.selectedImage != nil ? "photo.fill" : "photo")
                                            .font(.system(size: Constants.Sizes.micIcon))
                                            .foregroundColor(Constants.Colors.primaryBlue)
                                            .padding(Constants.Spacing.medium)
                                            .background(Constants.Colors.micInactiveBackground)
                                            .clipShape(Circle())
                                    }
                                    .padding(.trailing, Constants.Spacing.small)
                                    .padding(.bottom, Constants.Spacing.medium)

                                    // Mic button (Whisper: record while active, transcribe when stopped)
                                    Button(action: {
                                        viewModel.toggleSpeechRecognition()
                                    }) {
                                        Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                                            .font(.system(size: Constants.Sizes.micIcon))
                                            .foregroundColor(viewModel.isListening ? Constants.Colors.primaryRed : Constants.Colors.primaryBlue)
                                            .padding(Constants.Spacing.medium)
                                            .background(viewModel.isListening ? Constants.Colors.micActiveBackground : Constants.Colors.micInactiveBackground)
                                            .clipShape(Circle())
                                    }
                                    .disabled(viewModel.isTranscribingSpeech)
                                    .opacity(viewModel.isTranscribingSpeech ? 0.45 : 1)
                                    .padding(.trailing, Constants.Spacing.regular)
                                    .padding(.bottom, Constants.Spacing.medium)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $viewModel.showImagePicker) {
                        ImagePickerView(selectedImage: Binding(
                            get: { viewModel.selectedImage },
                            set: { viewModel.selectImage($0) }
                        ))
                    }
                    .sheet(isPresented: $viewModel.showCameraPicker) {
                        CameraPickerView(selectedImage: Binding(
                            get: { viewModel.selectedImage },
                            set: { viewModel.selectImage($0) }
                        ))
                    }
                    
                    // Log button
                    Button(action: {
                        // Dismiss keyboard
                        isTextFieldFocused = false
                        Task {
                            print("DEBUG: Log Meal button tapped")
                            await viewModel.logMeal()
                            print("DEBUG: Log Meal button action completed")
                        }
                    }) {
                        ZStack {
                            if viewModel.isLoading {
                                // Show Lottie animation when loading
                                LottieView(animationName: "LoadingAnimation", loopMode: LottieLoopMode.loop, contentMode: .scaleAspectFit)
                                    .frame(height: 24)
                            } else {
                                Text("Log Meal")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.isLoading 
                                ? Color.gray.opacity(0.3) 
                                : ((viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.selectedImage == nil) ? Constants.Colors.primaryGray : Constants.Colors.primaryBlue)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(Constants.Sizes.cornerRadius + 2)
                    }
                    .disabled((viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.selectedImage == nil) || viewModel.isLoading)
                    .padding(.horizontal)
                    
                    // Result card
                    if let result = viewModel.latestResult {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 0) {
                                HStack(alignment: .center, spacing: 8) {
                                    Text("Logged Successfully")
                                        .font(.headline)
                                    Text(result.mealType.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, Constants.Spacing.medium)
                                        .padding(.vertical, Constants.Spacing.small)
                                        .background(Constants.Colors.badgeBackground)
                                        .cornerRadius(Constants.Spacing.small)
                                }
                                Spacer(minLength: 12)
                                Button(action: {
                                    print("DEBUG: [HomeView] User dismissed meal preview (close)")
                                    mealPreviewAutoDismissWork?.cancel()
                                    mealPreviewAutoDismissWork = nil
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        viewModel.latestResult = nil
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                        .accessibilityLabel("Dismiss meal summary")
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text("Total Calories: \(Int(result.totalCalories))")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            // Macros row (meal totals or sum of items — same data history uses from rawResponseJson)
                            if let macros = result.resolvedMealMacrosForDisplay() {
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(Int(macros.protein))g")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Protein")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(Int(macros.carbs))g")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Carbs")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(Int(macros.fat))g")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Fat")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            
                            Divider()
                            
                            Text("Items:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(result.items.enumerated()), id: \.offset) { index, item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.name)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("\(Int(item.calories)) cal")
                                            .foregroundColor(.secondary)
                                    }
                                    Text("\(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    // Per-item macros (same style as History list / meal detail)
                                    if let p = item.protein, let c = item.carbs, let f = item.fat {
                                        MacrosCaptionLine(protein: p, carbs: c, fat: f)
                                            .padding(.top, 2)
                                    }
                                    if let assumptions = item.assumptions, !assumptions.isEmpty {
                                        Text("Assumptions: \(assumptions)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                
                                if index < result.items.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .padding()
                        .background(Constants.Colors.secondaryBackground)
                        .cornerRadius(Constants.Sizes.largeCornerRadius)
                        .padding(.horizontal)
                        .onAppear {
                            // Track analytics
                            AnalyticsService.trackMealSummaryViewed()
                            for item in result.items {
                                if item.protein == nil || item.carbs == nil || item.fat == nil {
                                    print("DEBUG: [HomeView] preview item '\(item.name)' missing macros p=\(String(describing: item.protein)) c=\(String(describing: item.carbs)) f=\(String(describing: item.fat))")
                                }
                            }
                        }
                    }
                    }
                .padding(.vertical)
            }
    }
    
    
}

/// Graphical date picker: dismisses as soon as the user taps a **different** calendar day (one tap). "Close" still available if they only browse months.
private struct LogDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @State private var dayBaselineForDismiss: Date?

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
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

                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        print("DEBUG: [LogDatePickerSheet] Close tapped")
                        isPresented = false
                    }
                }
            }
        }
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
            .onChange(of: viewModel.errorMessage) { oldValue, newValue in
                if let message = newValue, message != oldValue {
                    toastManager.show(ToastMessage(
                        title: "Error",
                        message: message,
                        type: .error
                    ))
                }
            }
    }
}

struct SpeechErrorModifier: ViewModifier {
    let viewModel: LogViewModel
    let toastManager: ToastManager
    
    func body(content: Content) -> some View {
        content
            .onChange(of: viewModel.speechService.errorMessage) { oldValue, newValue in
                if let message = newValue, message != oldValue {
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
        .modelContainer(for: MealEntry.self)
}

