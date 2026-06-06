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
    @AppStorage("proteinGoal") private var proteinGoal: Double = 150
    @AppStorage("carbsGoal") private var carbsGoal: Double = 200
    @AppStorage("fatGoal") private var fatGoal: Double = 65
    @AppStorage("dietStyle") private var dietStyle: String = DietStyle.balanced.rawValue
    
    @AppStorage("customProteinPercent") private var customProteinPercent: Double = 30
    @AppStorage("customCarbsPercent") private var customCarbsPercent: Double = 40
    @AppStorage("customFatPercent") private var customFatPercent: Double = 30
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var currentGoal: Double = 2000
    @State private var currentDietStyle: DietStyle = .balanced
    @State private var currentProteinPercent: Double = 30
    @State private var currentCarbsPercent: Double = 40
    @State private var currentFatPercent: Double = 30
    
    @State private var showHelperSheet = false
    @State private var isSaving = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.extraLarge) {
                // Subtitle
                Text("Set your daily calorie goal and diet style to track your macro targets effectively.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.top, Constants.Spacing.regular)
                
                // Goal Card (Calories)
                VStack(spacing: Constants.Spacing.large) {
                    HStack {
                        Image(systemName: "target")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.accentBlue)
                        
                        Text("Daily Calorie Goal")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Target")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Theme.secondaryText)
                        
                        Spacer()
                        
                        Text("\(Int(currentGoal)) cal")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    VStack(spacing: Constants.Spacing.small) {
                        HStack(spacing: Constants.Spacing.regular) {
                            Button(action: {
                                if currentGoal > 100 {
                                    currentGoal -= 50
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.primaryGreen)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Slider(
                                value: $currentGoal,
                                in: 100...5000,
                                step: 50
                            )
                            .tint(Theme.accentBlue)
                            
                            Button(action: {
                                if currentGoal < 5000 {
                                    currentGoal += 50
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.primaryGreen)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
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
                }
                .padding(Constants.Spacing.extraLarge)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                )
                .cornerRadius(Constants.Sizes.largeCornerRadius)
                .padding(.horizontal, Constants.Spacing.extraLarge)
                
                // Diet Style Card
                VStack(spacing: Constants.Spacing.large) {
                    HStack {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.primaryGreen)
                        
                        Text("Diet Style & Macro Split")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(DietStyle.allCases) { style in
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    currentDietStyle = style
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Text(style.rawValue)
                                        .font(.system(size: 14, weight: .bold))
                                    Spacer()
                                    if currentDietStyle == style {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(currentDietStyle == style ? Theme.primaryGreen : Theme.insetBackground(colorScheme: colorScheme))
                                .foregroundColor(currentDietStyle == style ? .white : Theme.primaryText(colorScheme: colorScheme))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(currentDietStyle == style ? Theme.primaryGreen : Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Help Finder Button
                    Button(action: {
                        showHelperSheet = true
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Help Me Choose")
                        }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryGreen)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Theme.softAccentBackground(colorScheme: colorScheme))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4)
                    
                    // Custom macro percentage steppers
                    if currentDietStyle == .custom {
                        VStack(spacing: Constants.Spacing.medium) {
                            Divider()
                                .background(Theme.cardBorder(colorScheme: colorScheme))
                                .padding(.vertical, 4)
                            
                            Text("Adjust Percentages (Must sum to 100%)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Stepper(value: $currentProteinPercent, in: 0...100, step: 2.5) {
                                HStack {
                                    Text("Protein:")
                                        .font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Text(formatPercent(currentProteinPercent))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Theme.proteinColor)
                                }
                            }
                            
                            Stepper(value: $currentCarbsPercent, in: 0...100, step: 2.5) {
                                HStack {
                                    Text("Carbohydrates:")
                                        .font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Text(formatPercent(currentCarbsPercent))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Theme.carbsColor)
                                }
                            }
                            
                            Stepper(value: $currentFatPercent, in: 0...100, step: 2.5) {
                                HStack {
                                    Text("Fats:")
                                        .font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Text(formatPercent(currentFatPercent))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Theme.fatColor)
                                }
                            }
                            
                            let totalPercent = currentProteinPercent + currentCarbsPercent + currentFatPercent
                            
                            HStack {
                                Text("Total Percentage")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                Spacer()
                                Text(formatPercent(totalPercent))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(totalPercent == 100 ? Theme.primaryGreen : Theme.dangerRed)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(Constants.Spacing.extraLarge)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                )
                .cornerRadius(Constants.Sizes.largeCornerRadius)
                .padding(.horizontal, Constants.Spacing.extraLarge)
                
                // Macro Breakdown Preview Card
                let currentPercentages: (protein: Double, carbs: Double, fat: Double) = {
                    if currentDietStyle != .custom {
                        return currentDietStyle.macroPercentages
                    } else {
                        return (currentProteinPercent / 100.0, currentCarbsPercent / 100.0, currentFatPercent / 100.0)
                    }
                }()
                
                let grams = DietStyle.calculateGrams(
                    calories: currentGoal,
                    proteinPercent: currentPercentages.protein,
                    carbsPercent: currentPercentages.carbs,
                    fatPercent: currentPercentages.fat
                )
                
                VStack(spacing: Constants.Spacing.large) {
                    HStack {
                        Image(systemName: "list.bullet.indent")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.primaryGreen)
                        
                        Text("Calculated Daily Targets")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    macroPreviewRow(
                        name: "Protein",
                        grams: grams.protein,
                        percent: currentPercentages.protein,
                        color: Theme.proteinColor,
                        kcal: grams.protein * 4
                    )
                    
                    macroPreviewRow(
                        name: "Carbohydrates",
                        grams: grams.carbs,
                        percent: currentPercentages.carbs,
                        color: Theme.carbsColor,
                        kcal: grams.carbs * 4
                    )
                    
                    macroPreviewRow(
                        name: "Fats",
                        grams: grams.fat,
                        percent: currentPercentages.fat,
                        color: Theme.fatColor,
                        kcal: grams.fat * 9
                    )
                }
                .padding(Constants.Spacing.extraLarge)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                )
                .cornerRadius(Constants.Sizes.largeCornerRadius)
                .padding(.horizontal, Constants.Spacing.extraLarge)
                
                // Save Button
                let isCustomValid = currentDietStyle != .custom || (currentProteinPercent + currentCarbsPercent + currentFatPercent == 100)
                
                PrimaryButton(title: isSaving ? "Saving..." : "Save Goal") {
                    Task {
                        isSaving = true
                        
                        let finalProtein = grams.protein
                        let finalCarbs = grams.carbs
                        let finalFat = grams.fat
                        
                        if currentDietStyle == .custom {
                            customProteinPercent = currentProteinPercent
                            customCarbsPercent = currentCarbsPercent
                            customFatPercent = currentFatPercent
                        }
                        
                        // Save to AppStorage
                        dailyGoal = currentGoal
                        dietStyle = currentDietStyle.rawValue
                        proteinGoal = finalProtein
                        carbsGoal = finalCarbs
                        fatGoal = finalFat
                        
                        // Sync to cloud
                        await cloudSyncService.syncUserPreferencesToCloud(
                            dailyGoal: currentGoal,
                            proteinGoal: finalProtein,
                            carbsGoal: finalCarbs,
                            fatGoal: finalFat,
                            dietStyle: currentDietStyle.rawValue
                        )
                        
                        AnalyticsService.trackDailyGoalChanged(newGoal: currentGoal)
                        
                        isSaving = false
                        dismiss()
                    }
                }
                .disabled(isSaving || !isCustomValid)
                .padding(.horizontal, Constants.Spacing.extraLarge)
                .padding(.bottom, Constants.Spacing.extraLarge)
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? 650 : .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .navigationTitle("Daily Targets")
        .navigationBarTitleDisplayMode(.large)
        .background(Theme.backgroundColor(colorScheme: colorScheme))
        .onAppear {
            currentGoal = dailyGoal
            currentDietStyle = DietStyle(rawValue: dietStyle) ?? .balanced
            currentProteinPercent = customProteinPercent
            currentCarbsPercent = customCarbsPercent
            currentFatPercent = customFatPercent
        }
        .sheet(isPresented: $showHelperSheet) {
            DietStyleHelperView(calorieGoal: currentGoal) { recommendedStyle in
                currentDietStyle = recommendedStyle
                if recommendedStyle == .custom {
                    currentProteinPercent = customProteinPercent
                    currentCarbsPercent = customCarbsPercent
                    currentFatPercent = customFatPercent
                }
            }
        }
    }
    
    private func macroPreviewRow(
        name: String,
        grams: Double,
        percent: Double,
        color: Color,
        kcal: Double
    ) -> some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                }
                
                Spacer()
                
                Text("\(Int(grams))g")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                
                Text("(\(Int(round(percent * 100)))% • \(Int(round(kcal))) kcal)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.insetBackground(colorScheme: colorScheme))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(percent), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
    
    private func formatPercent(_ value: Double) -> String {
        let isInteger = value.truncatingRemainder(dividingBy: 1) == 0
        return String(format: isInteger ? "%.0f%%" : "%.1f%%", value)
    }
}

#Preview {
    NavigationStack {
        DailyGoalView()
            .environmentObject(CloudSyncService())
    }
}
