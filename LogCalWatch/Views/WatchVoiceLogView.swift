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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if viewModel.isLoading {
                    // Loading State
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(WatchTheme.primaryGreenGlow)
                            .scaleEffect(1.2)
                        
                        Text("Analyzing & logging...")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(WatchTheme.mutedText)
                    }
                    .padding(.vertical, 35)
                } else if let err = viewModel.errorMessage {
                    // Error State
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        
                        Text(err)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Dismiss")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(WatchTheme.cardBackground)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(10)
                } else if viewModel.showConfirmation, let cal = viewModel.estimatedCalories {
                    // Auto-Logged Result Card with In-Place Update & Items Breakdown
                    VStack(spacing: 8) {
                        // Success Badge
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(WatchTheme.primaryGreenGlow)
                                .font(.system(size: 12))
                            Text("Meal Logged!")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(WatchTheme.primaryGreenGlow)
                        }
                        
                        Text(viewModel.spokenText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(WatchTheme.mutedText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text("\(Int(cal)) cal")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
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
                        
                        // Itemized Breakdown Cards
                        if !viewModel.parsedItems.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(viewModel.parsedItems) { item in
                                    HStack(alignment: .center, spacing: 4) {
                                        Circle()
                                            .fill(WatchTheme.primaryGreenGlow)
                                            .frame(width: 4, height: 4)
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(item.name)
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            if !item.quantity.isEmpty && item.quantity != "1 serving" {
                                                Text(item.quantity)
                                                    .font(.system(size: 9, weight: .regular, design: .rounded))
                                                    .foregroundColor(WatchTheme.mutedText)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(Int(item.calories)) cal")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(WatchTheme.primaryGreenGlow)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(WatchTheme.insetBackground)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.top, 2)
                        }
                        
                        // In-Place Update Button (Re-opens dictation directly)
                        TextFieldLink(prompt: Text("Speak update...")) {
                            HStack(spacing: 5) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Update Description")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(WatchTheme.cardBackground)
                            .foregroundColor(WatchTheme.primaryGreenGlow)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(WatchTheme.cardBorder, lineWidth: 1)
                            )
                        } onSubmit: { updatedText in
                            let trimmed = updatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            Task {
                                await viewModel.updateLoggedMeal(newText: trimmed)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                        
                        // Done Button
                        Button {
                            viewModel.resetInput()
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(WatchTheme.primaryGreen)
                                .foregroundColor(.white)
                                .cornerRadius(14)
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
                    // Initial Voice Log Screen
                    VStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 28))
                            .foregroundColor(WatchTheme.primaryGreenGlow)
                            .padding(.top, 6)
                        
                        Text("Dictate your meal")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        TextFieldLink(prompt: Text("Speak or type meal...")) {
                            HStack(spacing: 6) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Speak Meal")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(WatchTheme.primaryGreenGlow)
                            .cornerRadius(20)
                        } onSubmit: { text in
                            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            Task {
                                await viewModel.analyzeAndAutoLogMeal(trimmed)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(WatchTheme.cardBackground)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(WatchTheme.cardBorder, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
    }
}
