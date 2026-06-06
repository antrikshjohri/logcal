//
//  DietStyleHelperView.swift
//  logcal
//
//  Created by Antigravity on 04/06/26.
//

import SwiftUI

struct DietStyleHelperView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    let calorieGoal: Double
    let onApply: (DietStyle) -> Void
    
    @State private var currentStep = 0
    @State private var selectedGoal: GoalOption = .health
    @State private var selectedActivity: ActivityOption = .active
    @State private var selectedCarbPref: CarbOption = .normal
    
    private let totalSteps = 3
    
    enum GoalOption: String, CaseIterable {
        case muscle = "Build Muscle & Strength"
        case fatLoss = "Fat Loss & Tone"
        case health = "General Health & Wellness"
        
        var icon: String {
            switch self {
            case .muscle: return "figure.strengthtraining.traditional"
            case .fatLoss: return "flame.fill"
            case .health: return "heart.text.square.fill"
            }
        }
        
        var description: String {
            switch self {
            case .muscle: return "Support muscle recovery and growth with higher protein."
            case .fatLoss: return "Increase protein and manage carbs to burn fat and maintain fullness."
            case .health: return "Maintain steady daily energy levels with a balanced mix."
            }
        }
    }

    enum ActivityOption: String, CaseIterable {
        case sedentary = "Sedentary"
        case active = "Moderately Active"
        case veryActive = "Highly Active"
        
        var icon: String {
            switch self {
            case .sedentary: return "briefcase.fill"
            case .active: return "figure.walk"
            case .veryActive: return "figure.run"
            }
        }
        
        var description: String {
            switch self {
            case .sedentary: return "Mainly sitting during the day, light exercise."
            case .active: return "Standing/walking during work, or exercising 3-4x/week."
            case .veryActive: return "Intense exercise daily or highly physical occupation."
            }
        }
    }

    enum CarbOption: String, CaseIterable {
        case normal = "Enjoy Carbs"
        case lowCarb = "Low Carb"
        case keto = "Ketogenic"
        
        var icon: String {
            switch self {
            case .normal: return "leaf.fill"
            case .lowCarb: return "scalemass.fill"
            case .keto: return "chart.pie.fill"
            }
        }
        
        var description: String {
            switch self {
            case .normal: return "Eat grains, oats, fruit, and feel energized by them."
            case .lowCarb: return "Prefer higher fat, protein, and lighter carb intake."
            case .keto: return "Achieve ketosis with minimal carbs (under 50g) and high fat."
            }
        }
    }
    
    private var recommendedStyle: DietStyle {
        if selectedCarbPref == .keto {
            return .keto
        }
        if selectedCarbPref == .lowCarb {
            return .lowCarb
        }
        if selectedGoal == .health {
            return .balanced
        }
        if (selectedGoal == .muscle || selectedGoal == .fatLoss) && (selectedActivity == .active || selectedActivity == .veryActive) {
            return .highProtein
        }
        return .balanced
    }
    
    private var styleExplanation: String {
        switch recommendedStyle {
        case .balanced:
            return "A Balanced split (30% Protein / 40% Carbs / 30% Fat) is perfect for general health, steady energy, and supporting active workouts while enjoying a variety of foods."
        case .highProtein:
            return "A High Protein split (40% Protein / 30% Carbs / 30% Fat) is ideal to rebuild muscle, support strength training, and maximize satiety for fat loss."
        case .lowCarb:
            return "A Low Carb split (25% Protein / 15% Carbs / 60% Fat) helps keep blood sugar levels steady and utilizes fats as a primary source of daily energy."
        case .keto:
            return "A Ketogenic split (20% Protein / 5% Carbs / 75% Fat) shifts your body's metabolism to use ketones from fats rather than glucose from carbohydrates."
        case .custom:
            return ""
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar (hidden on result screen)
                if currentStep < totalSteps {
                    ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                        .tint(Theme.primaryGreen)
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                        .padding(.top, Constants.Spacing.large)
                }
                
                // Content area
                VStack {
                    switch currentStep {
                    case 0:
                        goalStepView
                    case 1:
                        activityStepView
                    case 2:
                        carbStepView
                    default:
                        recommendationResultView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Footer Navigation
                if currentStep < totalSteps {
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        }
                        
                        Spacer()
                        
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.primaryGreen)
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.vertical, Constants.Spacing.large)
                    .background(Theme.cardBackground(colorScheme: colorScheme))
                    .overlay(
                        Divider()
                            .background(Theme.cardBorder(colorScheme: colorScheme)),
                        alignment: .top
                    )
                }
            }
            .navigationTitle(currentStep < totalSteps ? "Step \(currentStep + 1) of \(totalSteps)" : "Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryGreen)
                }
            }
            .background(Theme.backgroundColor(colorScheme: colorScheme))
        }
    }
    
    // MARK: - Step Views
    
    private var goalStepView: some View {
        VStack(spacing: Constants.Spacing.large) {
            stepHeader(
                title: "What is your primary goal?",
                subtitle: "Your fitness objectives determine how much protein and energy you need daily."
            )
            
            VStack(spacing: Constants.Spacing.regular) {
                ForEach(GoalOption.allCases, id: \.self) { option in
                    selectionRow(
                        title: option.rawValue,
                        description: option.description,
                        icon: option.icon,
                        isSelected: selectedGoal == option
                    ) {
                        selectedGoal = option
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.extraLarge)
            
            Spacer()
        }
    }
    
    private var activityStepView: some View {
        VStack(spacing: Constants.Spacing.large) {
            stepHeader(
                title: "What is your activity level?",
                subtitle: "More active lifestyles burn more carbs and benefit from higher protein recovery."
            )
            
            VStack(spacing: Constants.Spacing.regular) {
                ForEach(ActivityOption.allCases, id: \.self) { option in
                    selectionRow(
                        title: option.rawValue,
                        description: option.description,
                        icon: option.icon,
                        isSelected: selectedActivity == option
                    ) {
                        selectedActivity = option
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.extraLarge)
            
            Spacer()
        }
    }
    
    private var carbStepView: some View {
        VStack(spacing: Constants.Spacing.large) {
            stepHeader(
                title: "What are your food preferences?",
                subtitle: "Choose whether you digest carbs well or prefer high fat/low carb style meals."
            )
            
            VStack(spacing: Constants.Spacing.regular) {
                ForEach(CarbOption.allCases, id: \.self) { option in
                    selectionRow(
                        title: option.rawValue,
                        description: option.description,
                        icon: option.icon,
                        isSelected: selectedCarbPref == option
                    ) {
                        selectedCarbPref = option
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.extraLarge)
            
            Spacer()
        }
    }
    
    private var recommendationResultView: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.extraLarge) {
                // Curated visual result badge
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.primaryGreen)
                        .padding(.top, 16)
                    
                    Text("Recommended Diet Style")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .textCase(.uppercase)
                    
                    Text(recommendedStyle.rawValue)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                }
                
                // Recommendation Explanation Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(styleExplanation)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .lineSpacing(4)
                }
                .padding(20)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                )
                .padding(.horizontal, Constants.Spacing.extraLarge)
                
                // Visual Macro Percentages & Grams Split
                let percentages = recommendedStyle.macroPercentages
                let grams = DietStyle.calculateGrams(
                    calories: calorieGoal,
                    proteinPercent: percentages.protein,
                    carbsPercent: percentages.carbs,
                    fatPercent: percentages.fat
                )
                
                VStack(spacing: Constants.Spacing.large) {
                    Text("Your Daily Targets (\(Int(calorieGoal)) kcal)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Macro row cards
                    macroBreakdownRow(
                        name: "Protein",
                        grams: grams.protein,
                        percent: percentages.protein,
                        color: Theme.proteinColor,
                        kcal: grams.protein * 4
                    )
                    
                    macroBreakdownRow(
                        name: "Carbs",
                        grams: grams.carbs,
                        percent: percentages.carbs,
                        color: Theme.carbsColor,
                        kcal: grams.carbs * 4
                    )
                    
                    macroBreakdownRow(
                        name: "Fat",
                        grams: grams.fat,
                        percent: percentages.fat,
                        color: Theme.fatColor,
                        kcal: grams.fat * 9
                    )
                }
                .padding(20)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                )
                .padding(.horizontal, Constants.Spacing.extraLarge)
                
                // Buttons
                VStack(spacing: 12) {
                    PrimaryButton(title: "Apply & Save") {
                        onApply(recommendedStyle)
                        dismiss()
                    }
                    
                    Button("Retake Questionnaire") {
                        withAnimation {
                            currentStep = 0
                        }
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.primaryGreen)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, Constants.Spacing.extraLarge)
                .padding(.bottom, Constants.Spacing.extraLarge)
            }
        }
    }
    
    // MARK: - View Helpers
    
    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(subtitle)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Constants.Spacing.extraLarge)
        .padding(.top, Constants.Spacing.large)
    }
    
    private func selectionRow(
        title: String,
        description: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Constants.Spacing.large) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.primaryGreen : Theme.insetBackground(colorScheme: colorScheme))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Theme.primaryText(colorScheme: colorScheme))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    
                    Text(description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Theme.primaryGreen : Theme.mutedText(colorScheme: colorScheme).opacity(0.4))
            }
            .padding(16)
            .background(Theme.cardBackground(colorScheme: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.primaryGreen : Theme.cardBorder(colorScheme: colorScheme), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func macroBreakdownRow(
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
                
                Text("(\(Int(percent * 100))% • \(Int(kcal)) kcal)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
            }
            
            // Custom modern progress bar
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
}

#Preview {
    DietStyleHelperView(calorieGoal: 2000) { _ in }
}
