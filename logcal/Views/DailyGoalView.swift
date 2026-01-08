//
//  DailyGoalView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct DailyGoalView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var cloudSyncService: CloudSyncService
    @AppStorage("dailyGoal") private var dailyGoal: Double = 2000
    @State private var currentGoal: Double = 2000
    @State private var isSaving = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.extraLarge) {
                // Subtitle
                Text("Set your daily calorie goal to track your progress effectively.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.top, Constants.Spacing.regular)
                
                // Goal Card
                VStack(spacing: Constants.Spacing.large) {
                    // Header
                    HStack {
                        Image(systemName: "target")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.accentBlue)
                        
                        Text("Daily Calorie Goal")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    // Target row
                    HStack {
                        Text("Target")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Theme.secondaryText)
                        
                        Spacer()
                        
                        Text("\(Int(currentGoal)) cal")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    // Slider
                    VStack(spacing: Constants.Spacing.small) {
                        Slider(
                            value: $currentGoal,
                            in: 100...5000,
                            step: 50
                        )
                        .tint(Theme.accentBlue)
                        
                        // Min/Max labels
                        HStack {
                            Text("100")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Theme.secondaryText)
                            
                            Spacer()
                            
                            Text("5,000")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Theme.secondaryText)
                        }
                    }
                    
                    // Helper text
                    Text("Your daily calorie goal helps maintain a healthy lifestyle and achieve your fitness objectives.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Theme.secondaryText)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Constants.Spacing.extraLarge)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                )
                .cornerRadius(Constants.Sizes.largeCornerRadius)
                .padding(.horizontal, Constants.Spacing.extraLarge)
                
                // Save button
                PrimaryButton(title: isSaving ? "Saving..." : "Save Goal") {
                    Task {
                        isSaving = true
                        dailyGoal = currentGoal
                        // Sync to Firestore
                        await cloudSyncService.syncDailyGoalToCloud(currentGoal)
                        
                        // Track analytics
                        AnalyticsService.trackDailyGoalChanged(newGoal: currentGoal)
                        
                        isSaving = false
                        dismiss()
                    }
                }
                .disabled(isSaving)
                .padding(.horizontal, Constants.Spacing.extraLarge)
                .padding(.bottom, Constants.Spacing.extraLarge)
            }
        }
        .navigationTitle("Daily Goal")
        .navigationBarTitleDisplayMode(.large)
        .background(Theme.backgroundColor(colorScheme: colorScheme))
        .onAppear {
            currentGoal = dailyGoal
        }
    }
}

#Preview {
    NavigationView {
        DailyGoalView()
    }
}

