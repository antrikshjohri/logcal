//
//  TodaysCaloriesCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct TodaysCaloriesCard: View {
    @Environment(\.colorScheme) var colorScheme
    let calories: Double
    let goal: Double
    let progress: Double
    var activeBurned: Double? = nil
    var adjustGoalWithActiveBurn: Bool = false

    private var effectiveGoal: Double {
        if adjustGoalWithActiveBurn, let burn = activeBurned, burn > 0 {
            return goal + burn
        }
        return goal
    }

    private var isOverGoal: Bool { calories > effectiveGoal }
    private var remainingUnderGoal: Double { max(0, effectiveGoal - calories) }
    private var amountOverGoal: Double { max(0, calories - effectiveGoal) }

    private var overBudgetAccent: Color {
        colorScheme == .dark ? Color(red: 1.0, green: 0.68, blue: 0.32) : Theme.warningAmber
    }

    private var accentColor: Color {
        isOverGoal ? overBudgetAccent : Theme.primaryGreen
    }
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            // Top Row: Calories Eaten (Left) & Progress Ring (Right)
            HStack(alignment: .center, spacing: 0) {
                // Eaten amount
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatNumber(calories))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    
                    if adjustGoalWithActiveBurn, let burn = activeBurned, burn > 0 {
                        Text("of \(formatNumber(effectiveGoal)) cal (\(formatNumber(goal)) + \(formatNumber(burn)) 🔥)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    } else {
                        Text("of \(formatNumber(goal)) cal eaten")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                }
                
                Spacer()
                
                // Progress Ring with nested icon & label
                ZStack {
                    ProgressRingView(
                        progress: progress,
                        size: 90,
                        strokeWidth: 8,
                        ringColor: accentColor
                    )
                    
                    VStack(spacing: 2) {
                        Image(systemName: "leaf")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(accentColor)
                        
                        Text("\(Int(round(progress * 100)))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    }
                }
            }
            
            // Bottom Row: Status Pill/Badge spanning the width + Active Burn pill if present
            HStack(spacing: 8) {
                Image(systemName: isOverGoal ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
                
                Text("\(Int(isOverGoal ? amountOverGoal : remainingUnderGoal)) cal \(isOverGoal ? "over target" : "remaining")")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(accentColor)
                
                Spacer()
                
                if let burn = activeBurned, burn > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text("\(Int(burn)) burned")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(accentColor.opacity(colorScheme == .dark ? 0.15 : 0.08))
            .cornerRadius(Constants.Sizes.cornerRadius)
        }
        .padding(24)
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
    
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(number))) ?? "\(Int(number))"
    }
}
