//
//  WatchVoiceLogView.swift
//  LogCalWatch
//
//  Created by Antriksh Johri on 17/08/26.
//

import SwiftUI

struct WatchVoiceLogView: View {
    @ObservedObject var viewModel: WatchLogViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var textInput: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if viewModel.isLoading {
                    // Loading State with Pulsing Wave
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(WatchTheme.primaryGreenGlow)
                            .scaleEffect(1.2)
                        
                        Text("Analyzing meal...")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(WatchTheme.mutedText)
                    }
                    .padding(.vertical, 30)
                } else if viewModel.showConfirmation, let cal = viewModel.estimatedCalories {
                    // Confirmation & Result Card
                    VStack(spacing: 8) {
                        Text(viewModel.spokenText)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text("\(Int(cal)) cal")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(WatchTheme.primaryGreenGlow)
                        
                        if let p = viewModel.estimatedProtein, let c = viewModel.estimatedCarbs, let f = viewModel.estimatedFat {
                            HStack(spacing: 8) {
                                Text("P: \(Int(p))g")
                                    .foregroundColor(WatchTheme.proteinColor)
                                Text("C: \(Int(c))g")
                                    .foregroundColor(WatchTheme.carbsColor)
                                Text("F: \(Int(f))g")
                                    .foregroundColor(WatchTheme.fatColor)
                            }
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        
                        Button {
                            viewModel.confirmAndLogMeal()
                            dismiss()
                        } label: {
                            Text("Log Meal")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(WatchTheme.primaryGreen)
                                .foregroundColor(.white)
                                .cornerRadius(18)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                        
                        Button {
                            viewModel.resetInput()
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(WatchTheme.mutedText)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(WatchTheme.cardBackground)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(WatchTheme.cardBorder, lineWidth: 1)
                    )
                } else {
                    // Initial Voice Dictation Input Prompt
                    VStack(spacing: 10) {
                        Image(systemName: "waveform.badge.mic")
                            .font(.system(size: 28))
                            .foregroundColor(WatchTheme.primaryGreenGlow)
                            .padding(.top, 6)
                        
                        TextField("Tap to speak meal...", text: $textInput)
                            .font(.system(size: 13, design: .rounded))
                            .focused($isInputFocused)
                            .onSubmit {
                                guard !textInput.isEmpty else { return }
                                Task {
                                    await viewModel.analyzeSpokenMeal(textInput)
                                }
                            }
                        
                        if !textInput.isEmpty {
                            Button {
                                Task {
                                    await viewModel.analyzeSpokenMeal(textInput)
                                }
                            } label: {
                                Text("Calculate Calories")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(WatchTheme.primaryGreen)
                                    .foregroundColor(.white)
                                    .cornerRadius(18)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onAppear {
                        isInputFocused = true
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
