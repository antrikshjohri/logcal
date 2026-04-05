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

    private var isOverGoal: Bool { calories > goal }
    private var remainingUnderGoal: Double { max(0, goal - calories) }
    private var amountOverGoal: Double { max(0, calories - goal) }

    /// Informative amber/orange — not error red.
    private var overBudgetAccent: Color {
        colorScheme == .dark ? Color(red: 1, green: 0.72, blue: 0.35) : Color(red: 0.85, green: 0.45, blue: 0)
    }
    
    var body: some View {
        DashboardCard {
            VStack(spacing: Constants.Spacing.large) {
                // Header
                HStack {
                    Text("Today's Calories")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.secondaryText)
                }
                
                // Main content
                HStack(alignment: .top, spacing: Constants.Spacing.extraLarge) {
                    // Left: Calories and goal
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("\(Int(calories))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("of \(Int(goal)) cal")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Right: Progress ring (warmer accent when over goal — still capped at full ring)
                    ProgressRingView(
                        progress: progress,
                        ringColor: isOverGoal ? overBudgetAccent : nil
                    )
                }
                
                // Divider
                Divider()
                    .background(Theme.cardBorder(colorScheme: colorScheme))
                
                // Bottom: remaining under goal, or how far over (never "Remaining: 0" when over)
                if isOverGoal {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Over your goal by")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Theme.secondaryText)
                        Spacer()
                        Text("\(Int(amountOverGoal)) cal")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(overBudgetAccent)
                    }
                } else {
                    HStack {
                        Text("Remaining")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Theme.secondaryText)
                        Spacer()
                        Text("\(Int(remainingUnderGoal)) cal")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.accentBlue)
                    }
                }
            }
        }
    }
}

