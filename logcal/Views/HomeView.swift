//
//  HomeView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData
import Lottie

struct HomeView: View {
    @StateObject private var viewModel = LogViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var toastManager: ToastManager
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isTextFieldFocused: Bool
    @AppStorage("navigateToDate") private var navigateToDateTimestamp: Double = 0
    @State private var showConfetti = false
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Log Calories")
                .onChange(of: viewModel.latestResult) { oldValue, newValue in
                    if oldValue == nil && newValue != nil {
                        showConfetti = true
                        // Auto-dismiss confetti after animation completes (3 seconds)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            showConfetti = false
                        }
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
                        NavigationView {
                            VStack {
                                DatePicker(
                                    "Select Date",
                                    selection: $viewModel.selectedDate,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                                .padding()
                                
                                Spacer()
                            }
                            .navigationTitle("Select Date")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        viewModel.showDatePicker = false
                                    }
                                }
                            }
                        }
                    }
                    
                    // Food text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What did you eat?")
                            .font(.headline)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $viewModel.foodText)
                                .frame(minHeight: Constants.Sizes.textEditorMinHeight)
                                .padding(Constants.Spacing.medium)
                                .focused($isTextFieldFocused)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                        .stroke(Constants.Colors.borderGray, lineWidth: Constants.Sizes.borderWidth)
                                )
                            
                            // Placeholder text
                            if viewModel.foodText.isEmpty {
                                Text("Speak naturally about your meal...")
                                    .foregroundColor(Constants.Colors.primaryGray)
                                    .padding(.horizontal, Constants.Spacing.regular)
                                    .padding(.vertical, Constants.Spacing.large)
                                    .allowsHitTesting(false)
                            }
                            
                            // Mic button
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
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
                                    .padding(.trailing, Constants.Spacing.regular)
                                    .padding(.bottom, Constants.Spacing.medium)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
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
                                : (viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Constants.Colors.primaryGray : Constants.Colors.primaryBlue)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(Constants.Sizes.cornerRadius + 2)
                    }
                    .disabled(viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    .padding(.horizontal)
                    
                    // Result card
                    if let result = viewModel.latestResult {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Logged Successfully")
                                    .font(.headline)
                                Spacer()
                                Text(result.mealType.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, Constants.Spacing.medium)
                                    .padding(.vertical, Constants.Spacing.small)
                                    .background(Constants.Colors.badgeBackground)
                                    .cornerRadius(Constants.Spacing.small)
                            }
                            
                            Text("Total Calories: \(Int(result.totalCalories))")
                                .font(.title2)
                                .fontWeight(.bold)
                            
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
                            // Auto-dismiss after 10 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    viewModel.latestResult = nil
                                }
                            }
                        }
                    }
                    }
                .padding(.vertical)
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
                        title: "Speech Recognition Error",
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

