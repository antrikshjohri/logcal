//
//  WatchHomeView.swift
//  LogCalWatch
//
//  Created by Antriksh Johri on 17/08/26.
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject private var connectivity: WatchConnectivityManager
    @StateObject private var viewModel = WatchLogViewModel()
    @State private var showVoiceSheet: Bool = false
    @State private var showFavouritesSheet: Bool = false
    
    private var progress: Double {
        guard connectivity.dailyGoal > 0 else { return 0 }
        return min(connectivity.todayCalories / connectivity.dailyGoal, 1.0)
    }
    
    private var remainingCalories: Int {
        Int(max(connectivity.dailyGoal - connectivity.todayCalories, 0))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // Success toast if logged recently
                    if let success = viewModel.logSuccessMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(WatchTheme.primaryGreenGlow)
                            Text(success)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(WatchTheme.cardBackground)
                        .clipShape(Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Daily Calorie Ring Card
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .stroke(WatchTheme.cardBorder, lineWidth: 8)
                                .frame(width: 90, height: 90)
                            
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    LinearGradient(
                                        colors: [WatchTheme.primaryGreenGlow, WatchTheme.primaryGreen],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 90, height: 90)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                            
                            VStack(spacing: 1) {
                                Text("\(Int(connectivity.todayCalories))")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("/ \(Int(connectivity.dailyGoal))")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(WatchTheme.mutedText)
                            }
                        }
                        .padding(.top, 4)
                        
                        Text("\(remainingCalories) cal left")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(WatchTheme.primaryGreenGlow)
                    }
                    
                    // Quick Macros Row
                    HStack(spacing: 6) {
                        MacroMiniPill(label: "P", value: Int(connectivity.protein), color: WatchTheme.proteinColor)
                        MacroMiniPill(label: "C", value: Int(connectivity.carbs), color: WatchTheme.carbsColor)
                        MacroMiniPill(label: "F", value: Int(connectivity.fat), color: WatchTheme.fatColor)
                    }
                    
                    // Big Speak Mic Action Button
                    Button {
                        showVoiceSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(WatchTheme.primaryGreen.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(WatchTheme.primaryGreenGlow)
                            }
                            
                            Text("Speak Meal")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(WatchTheme.cardBackground)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(WatchTheme.primaryGreen.opacity(0.6), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Quick Favourites Section
                    if !connectivity.savedMeals.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Favourites")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(WatchTheme.mutedText)
                                Spacer()
                            }
                            
                            ForEach(connectivity.savedMeals.prefix(3)) { fav in
                                Button {
                                    viewModel.quickLogSavedMeal(fav)
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
                                        Text("+ \(Int(fav.totalCalories))")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(WatchTheme.primaryGreenGlow)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
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
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 12)
            }
            .sheet(isPresented: $showVoiceSheet) {
                WatchVoiceLogView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Macro Mini Pill
private struct MacroMiniPill: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text("\(value)g")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(WatchTheme.cardBackground)
        .cornerRadius(6)
    }
}
