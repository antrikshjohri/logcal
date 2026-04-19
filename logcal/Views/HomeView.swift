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
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isTextFieldFocused: Bool
    @AppStorage("navigateToDate") private var navigateToDateTimestamp: Double = 0
    @State private var showConfetti = false
    @State private var mealPreviewAutoDismissWork: DispatchWorkItem?
    @State private var quickEditPrompt = ""
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Log Calories")
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
                let isComposerBusy = viewModel.isListening || viewModel.isTranscribingSpeech
                let canSubmitMeal = viewModel.canSubmitMeal
                let stopButtonBackground = colorScheme == .dark
                    ? Color(white: 0.22)
                    : Constants.Colors.primaryBlue.opacity(0.18)
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
                                .allowsHitTesting(!viewModel.isListening && !viewModel.isTranscribingSpeech)
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

                            if viewModel.isTranscribingSpeech {
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
                                HStack(alignment: .center) {
                                    if viewModel.isListening {
                                        DictationWaveformView(samples: viewModel.waveformSamples)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading, Constants.Spacing.regular)
                                            .padding(.trailing, Constants.Spacing.small)
                                    } else {
                                        Spacer()
                                    }

                                    if !viewModel.isListening {
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
                                            .disabled(isComposerBusy)
                                            .opacity(isComposerBusy ? 0.45 : 1)
                                            .padding(.trailing, Constants.Spacing.small)
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
                                        .disabled(isComposerBusy)
                                        .opacity(isComposerBusy ? 0.45 : 1)
                                        .padding(.trailing, Constants.Spacing.small)
                                    }

                                    if viewModel.isListening {
                                        Button(action: {
                                            viewModel.cancelSpeechRecognition()
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: Constants.Sizes.micIcon - 1, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(Constants.Spacing.medium)
                                                .background(Color.red.opacity(0.9))
                                                .clipShape(Circle())
                                        }
                                        .padding(.trailing, Constants.Spacing.small)

                                        Button(action: {
                                            viewModel.stopSpeechRecognition()
                                        }) {
                                            Image(systemName: "stop.fill")
                                                .font(.system(size: Constants.Sizes.micIcon - 1))
                                                .foregroundColor(Constants.Colors.primaryBlue)
                                                .padding(Constants.Spacing.medium)
                                                .background(stopButtonBackground)
                                                .clipShape(Circle())
                                        }
                                        .padding(.trailing, Constants.Spacing.small)
                                    }

                                    // Mic/send button (record while idle, transcribe+log while listening)
                                    Button(action: {
                                        if viewModel.isListening {
                                            isTextFieldFocused = false
                                            Task {
                                                print("DEBUG: Send tapped while dictating")
                                                await viewModel.logMeal()
                                                print("DEBUG: Send while dictating completed")
                                            }
                                        } else {
                                            isTextFieldFocused = false
                                            viewModel.toggleSpeechRecognition()
                                        }
                                    }) {
                                        Image(systemName: viewModel.isListening ? "arrow.up" : "mic")
                                            .font(.system(size: Constants.Sizes.micIcon))
                                            .foregroundColor(viewModel.isListening ? .white : Constants.Colors.primaryBlue)
                                            .padding(Constants.Spacing.medium)
                                            .background(viewModel.isListening ? Constants.Colors.primaryBlue : Constants.Colors.micInactiveBackground)
                                            .clipShape(Circle())
                                    }
                                    .disabled(viewModel.isTranscribingSpeech)
                                    .opacity(viewModel.isTranscribingSpeech ? 0.45 : 1)
                                    .padding(.trailing, Constants.Spacing.regular)
                                }
                                .padding(.bottom, Constants.Spacing.medium)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .onChange(of: viewModel.isListening) { _, isListening in
                        if isListening {
                            isTextFieldFocused = false
                        }
                    }
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
                                : (canSubmitMeal ? Constants.Colors.primaryBlue : Constants.Colors.primaryGray)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(Constants.Sizes.cornerRadius + 2)
                    }
                    .disabled(!canSubmitMeal || viewModel.isLoading || viewModel.isTranscribingSpeech)
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
                                    quickEditPrompt = ""
                                    viewModel.errorMessage = nil
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

                            Divider()
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
        NavigationStack {
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
            ? Constants.Colors.primaryBlue.opacity(0.55)
            : Constants.Colors.primaryBlue.opacity(0.9)
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
        .modelContainer(for: MealEntry.self)
}
