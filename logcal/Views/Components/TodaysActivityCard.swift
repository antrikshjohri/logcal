//
//  TodaysActivityCard.swift
//  logcal
//
//  Created by Antriksh Johri on 20/08/26.
//

import SwiftUI

struct TodaysActivityCard: View {
    @Environment(\.colorScheme) var colorScheme
    let activeBurn: Double
    let basalBurn: Double
    let consumedCalories: Double
    let steps: Int
    let workouts: [HealthWorkoutItem]
    
    @State private var showExplanationSheet = false
    
    private var totalBurn: Double {
        basalBurn + activeBurn
    }
    
    private var netBalance: Double {
        totalBurn - consumedCalories
    }
    
    private var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. Header with Info (i) Button
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(colorScheme == .dark ? 0.25 : 0.12))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Activity & Energy Balance")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        
                        Text("Apple Health")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                }
                
                Spacer()
                
                Button {
                    showExplanationSheet = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            // 2. Stats Grid (Active Calories, Total Calories (by midnight), Steps)
            HStack(spacing: 8) {
                // Tile 1: Active Calories
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Active Calories")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text(" ")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                    }
                    .frame(height: 26, alignment: .topLeading)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(activeBurn))")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        Text("cal")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Theme.insetBackground(colorScheme: colorScheme))
                .cornerRadius(12)
                
                // Tile 2: Total Calories (by midnight)
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Total Calories")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text("(by midnight)")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(height: 26, alignment: .topLeading)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(totalBurn))")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        Text("cal")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Theme.insetBackground(colorScheme: colorScheme))
                .cornerRadius(12)
                
                // Tile 3: Steps
                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Steps")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .lineLimit(1)
                        Text(" ")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                    }
                    .frame(height: 26, alignment: .topLeading)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(formattedSteps)
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        Text("st")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Theme.insetBackground(colorScheme: colorScheme))
                .cornerRadius(12)
            }
            
            // 3. Estimated Net Calorie Balance (24-Hour Projection)
            if totalBurn > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if netBalance >= 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.primaryGreen)
                                Text("Est. \(Int(netBalance)) kcal Deficit")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.primaryGreen)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.orange)
                                Text("Est. \(Int(-netBalance)) kcal Surplus")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.orange)
                            }
                        }
                        
                        Spacer()
                        
                        Text("Est. Burn \(Int(totalBurn)) • Eaten \(Int(consumedCalories))")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                    
                    // Visual Balance Progress Bar
                    GeometryReader { geo in
                        let maxVal = max(totalBurn, consumedCalories, 1.0)
                        let burnedRatio = min(1.0, totalBurn / maxVal)
                        let eatenRatio = min(1.0, consumedCalories / maxVal)
                        
                        ZStack(alignment: .leading) {
                            // Background track
                            Capsule()
                                .fill(Theme.insetBackground(colorScheme: colorScheme))
                                .frame(height: 8)
                            
                            // Burned bar
                            Capsule()
                                .fill(Color.orange.opacity(0.4))
                                .frame(width: geo.size.width * burnedRatio, height: 8)
                            
                            // Eaten bar
                            Capsule()
                                .fill(netBalance >= 0 ? Theme.primaryGreen : Color.orange)
                                .frame(width: geo.size.width * eatenRatio, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(12)
                .background(Theme.insetBackground(colorScheme: colorScheme))
                .cornerRadius(12)
            }
            
            // 4. Workouts Section
            VStack(alignment: .leading, spacing: 8) {
                Text(workouts.isEmpty ? "WORKOUTS" : "WORKOUTS (\(workouts.count))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    .padding(.top, 4)
                
                if workouts.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        Text("No workouts recorded for this day")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                    .padding(.vertical, 2)
                } else {
                    VStack(spacing: 8) {
                        ForEach(workouts) { workout in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.softAccentBackground(colorScheme: colorScheme))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: workout.iconName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Theme.primaryGreen)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(workout.title)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                    
                                    Text("\(formattedTime(workout.startDate)) • \(workout.durationMinutes) min")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                }
                                
                                Spacer()
                                
                                if workout.caloriesBurned > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.orange)
                                        Text("\(Int(workout.caloriesBurned)) cal")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(colorScheme == .dark ? 0.2 : 0.12))
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(10)
                            .background(Theme.insetBackground(colorScheme: colorScheme))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .fill(Theme.cardBackground(colorScheme: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
        )
        .shadow(color: Theme.shadowColor(colorScheme: colorScheme), radius: 18, x: 0, y: 10)
        .sheet(isPresented: $showExplanationSheet) {
            ActivityEnergyExplanationSheet()
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Activity & Energy Explanation Sheet
struct ActivityEnergyExplanationSheet: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Banner
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(colorScheme == .dark ? 0.25 : 0.12))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "flame.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Activity & Energy Guide")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            
                            Text("How your calorie expenditure is calculated")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        }
                    }
                    .padding(.top, 8)
                    
                    Divider()
                    
                    // Item 1: Active Calories
                    explanationRow(
                        icon: "figure.run",
                        iconColor: .orange,
                        title: "Active Calories",
                        description: "Energy burned from physical movement, walking, workouts, and exercise sessions logged on Apple Watch or iPhone."
                    )
                    
                    // Item 2: Total Calories (by midnight / TDEE)
                    explanationRow(
                        icon: "bolt.fill",
                        iconColor: Color(red: 0.95, green: 0.70, blue: 0.25),
                        title: "Total Calories (by midnight)",
                        description: "Your estimated 24-hour Total Daily Energy Expenditure (TDEE). This combines your baseline Resting Metabolic Rate (BMR) with your active movement."
                    )
                    
                    // Item 3: Steps
                    explanationRow(
                        icon: "shoeprints.fill",
                        iconColor: Theme.primaryGreen,
                        title: "Daily Steps",
                        description: "Step count tracked continuously by your Apple Watch and iPhone pedometer."
                    )
                    
                    // Item 4: Est. Deficit / Surplus
                    explanationRow(
                        icon: "arrow.left.arrow.right",
                        iconColor: Theme.accentBlue,
                        title: "Estimated Deficit & Surplus",
                        description: "The estimated net difference between your 24-hour total energy burn and total calories eaten today. A calorie deficit supports fat loss, while a surplus supports muscle gain."
                    )
                    
                    // Item 5: Apple Health Privacy Note
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        
                        Text("All activity data is read directly and securely from Apple Health on your device.")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Theme.backgroundColor(colorScheme: colorScheme).ignoresSafeArea())
            .navigationTitle("Energy & Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryGreen)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    @ViewBuilder
    private func explanationRow(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(colorScheme == .dark ? 0.25 : 0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                
                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    .lineSpacing(2)
            }
        }
        .padding(12)
        .background(Theme.insetBackground(colorScheme: colorScheme))
        .cornerRadius(12)
    }
}
