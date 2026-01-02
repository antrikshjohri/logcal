//
//  HomeView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var viewModel = LogViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isTextFieldFocused: Bool
    @AppStorage("navigateToDate") private var navigateToDateTimestamp: Double = 0
    
    var body: some View {
        NavigationView {
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
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Log Meal")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Constants.Colors.primaryGray : Constants.Colors.primaryBlue)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.Sizes.cornerRadius + 2)
                    }
                    .disabled(viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    .padding(.horizontal)
                    
                    // Error banner
                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(
                            title: "Error",
                            message: errorMessage,
                            type: .error
                        )
                    }
                    
                    // Speech recognition error banner
                    if let speechError = viewModel.speechService.errorMessage {
                        ErrorBanner(
                            title: "Speech Recognition Error",
                            message: speechError,
                            type: .warning
                        )
                    }
                    
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
                                    Text("Confidence: \(Int(item.confidence * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                    }
                    }
                .padding(.vertical)
            }
            .navigationTitle("Log Calories")
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .onChange(of: navigateToDateTimestamp) { oldValue, newValue in
                // When date is set from HistoryView, update viewModel
                if newValue > 0 && newValue != oldValue {
                    let date = Date(timeIntervalSince1970: newValue)
                    viewModel.selectedDate = date
                    // Reset the timestamp to prevent re-triggering
                    navigateToDateTimestamp = 0
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    // Dismiss keyboard when tapping anywhere (buttons will still work)
                    isTextFieldFocused = false
                }
            )
        }
    }
    
}

#Preview {
    HomeView()
        .modelContainer(for: MealEntry.self)
}

