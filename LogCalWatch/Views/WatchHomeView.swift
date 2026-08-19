//
//  WatchHomeView.swift
//  LogCalWatch
//
//  Created by Antriksh Johri on 17/08/26.
//

import SwiftUI
import WatchKit

struct WatchHomeView: View {
    @EnvironmentObject private var connectivity: WatchConnectivityManager
    @StateObject private var viewModel = WatchLogViewModel()
    @State private var showVoiceSheet: Bool = false
    @State private var selectedSavedMeal: WatchSavedMeal? = nil
    @Binding var openVoiceLogDirectly: Bool
    
    init(openVoiceLogDirectly: Binding<Bool> = .constant(false)) {
        self._openVoiceLogDirectly = openVoiceLogDirectly
    }
    
    private var progress: Double {
        guard connectivity.dailyGoal > 0 else { return 0 }
        return min(max(connectivity.todayCalories / connectivity.dailyGoal, 0.0), 1.0)
    }
    
    private var remainingCalories: Int {
        Int(max(connectivity.dailyGoal - connectivity.todayCalories, 0))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    // Success toast if logged recently
                    if let success = viewModel.logSuccessMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(WatchTheme.primaryGreenGlow)
                            Text(success)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(WatchTheme.cardBackground)
                        .clipShape(Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // 1. Lock-Screen Style Compact Summary Card (Calorie + Progress + 4 Macros)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Calories")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(WatchTheme.mutedText)
                            Spacer()
                            Text("\(Int(connectivity.todayCalories)) / \(Int(connectivity.dailyGoal))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        // Slim Horizontal Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(WatchTheme.cardBorder)
                                if progress > 0 {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [WatchTheme.primaryGreenGlow, WatchTheme.primaryGreen],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(geo.size.width * CGFloat(progress), 6))
                                }
                            }
                        }
                        .frame(height: 5)
                        
                        // 4 Macros Grid Row (P, C, F, Fib)
                        HStack(spacing: 4) {
                            MacroMiniPill(label: "P", value: Int(connectivity.protein), color: WatchTheme.proteinColor)
                            MacroMiniPill(label: "C", value: Int(connectivity.carbs), color: WatchTheme.carbsColor)
                            MacroMiniPill(label: "F", value: Int(connectivity.fat), color: WatchTheme.fatColor)
                            MacroMiniPill(label: "Fib", value: Int(connectivity.fiber), color: WatchTheme.fiberColor)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(WatchTheme.cardBackground)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(WatchTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // 2. 1-Tap Direct Voice Action Button (Fully visible without scroll)
                    TextFieldLink(prompt: Text("Speak or type meal...")) {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                            Text("Log Meal")
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
                        showVoiceSheet = true
                        Task {
                            await viewModel.analyzeAndAutoLogMeal(trimmed)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // 3. Favourites List (All saved meals)
                    if !connectivity.savedMeals.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Favourites")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(WatchTheme.mutedText)
                                Spacer()
                                Text("\(connectivity.savedMeals.count)")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(WatchTheme.mutedText)
                            }
                            
                            ForEach(connectivity.savedMeals) { fav in
                                Button {
                                    selectedSavedMeal = fav
                                } label: {
                                    HStack {
                                        Image(systemName: "bookmark.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(WatchTheme.primaryGreenGlow)
                                        Text(fav.title)
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(Int(fav.totalCalories)) cal")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(WatchTheme.primaryGreenGlow)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(WatchTheme.cardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(WatchTheme.cardBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 12)
            }
            .sheet(isPresented: $showVoiceSheet) {
                WatchVoiceLogView(viewModel: viewModel)
            }
            .sheet(item: $selectedSavedMeal) { meal in
                WatchSavedMealDetailView(meal: meal, viewModel: viewModel)
            }
            .onAppear {
                connectivity.requestInitialSync()
                if openVoiceLogDirectly {
                    openVoiceLogDirectly = false
                    startRootDictation()
                }
            }
            .task {
                connectivity.requestInitialSync()
            }
            .onChange(of: openVoiceLogDirectly) { newValue in
                if newValue {
                    openVoiceLogDirectly = false
                    startRootDictation()
                }
            }
        }
    }
    
    private func startRootDictation() {
        showVoiceSheet = false
        selectedSavedMeal = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            WKExtension.shared().visibleInterfaceController?.presentTextInputController(
                withSuggestions: nil,
                allowedInputMode: .plain
            ) { results in
                guard let text = (results as? [String])?.first,
                      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                Task { @MainActor in
                    self.showVoiceSheet = true
                    await self.viewModel.analyzeAndAutoLogMeal(trimmed)
                }
            }
        }
    }
}

// MARK: - Favourite Meal Detail Preview Sheet (2-Step Log)
struct WatchSavedMealDetailView: View {
    let meal: WatchSavedMeal
    @ObservedObject var viewModel: WatchLogViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Title and Meal Type Header
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 11))
                            .foregroundColor(WatchTheme.primaryGreenGlow)
                        Text(meal.mealType.capitalized)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(WatchTheme.mutedText)
                    }
                    
                    Text(meal.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.top, 2)
                
                // Calories Display
                Text("\(Int(meal.totalCalories)) cal")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(WatchTheme.primaryGreenGlow)
                
                // Macros Row
                HStack(spacing: 8) {
                    Text("P: \(Int(meal.protein))g")
                        .foregroundColor(WatchTheme.proteinColor)
                    Text("C: \(Int(meal.carbs))g")
                        .foregroundColor(WatchTheme.carbsColor)
                    Text("F: \(Int(meal.fat))g")
                        .foregroundColor(WatchTheme.fatColor)
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                
                // Upfront CTA - Log Meal Button
                Button {
                    viewModel.quickLogSavedMeal(meal)
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 13, weight: .bold))
                        Text("Log Meal")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(WatchTheme.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(18)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(10)
            .background(WatchTheme.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(WatchTheme.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Macro Mini Pill
private struct MacroMiniPill: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text("\(value)g")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(WatchTheme.insetBackground)
        .cornerRadius(6)
    }
}
