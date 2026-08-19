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
            // 1. Header
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
            }
            
            // 2. Stats Grid (Active Burn, Total TDEE, Steps)
            HStack(spacing: 10) {
                // Active Burn
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(activeBurn))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
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
                
                // Total Burn (TDEE)
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL (TDEE)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(totalBurn))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
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
                
                // Steps Stat
                VStack(alignment: .leading, spacing: 4) {
                    Text("STEPS")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(formattedSteps)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
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
            
            // 3. True Net Calorie Balance (Deficit / Surplus)
            if totalBurn > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if netBalance >= 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.primaryGreen)
                                Text("\(Int(netBalance)) kcal Deficit")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.primaryGreen)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.orange)
                                Text("\(Int(-netBalance)) kcal Surplus")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.orange)
                            }
                        }
                        
                        Spacer()
                        
                        Text("Burned \(Int(totalBurn)) • Eaten \(Int(consumedCalories))")
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
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
