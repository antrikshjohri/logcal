//
//  TodaysMacrosCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct TodaysMacrosCard: View {
    @Environment(\.colorScheme) var colorScheme
    let protein: Double
    let carbs: Double
    let fat: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double
    
    /// Progress ratio (can exceed 1.0 for display %). Ring draws up to 100%.
    private var proteinProgress: Double {
        proteinGoal > 0 ? protein / proteinGoal : 0
    }
    
    private var carbsProgress: Double {
        carbsGoal > 0 ? carbs / carbsGoal : 0
    }
    
    private var fatProgress: Double {
        fatGoal > 0 ? fat / fatGoal : 0
    }
    
    var body: some View {
        DashboardCard {
            VStack(spacing: Constants.Spacing.large) {
                HStack {
                    Text("Macro Balance")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    
                    Spacer()
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                }
                
                HStack(spacing: Constants.Spacing.regular) {
                    MacroProgressTile(
                        title: "Protein",
                        current: protein,
                        goal: proteinGoal,
                        progress: proteinProgress,
                        color: Theme.proteinColor
                    )

                    MacroProgressTile(
                        title: "Carbs",
                        current: carbs,
                        goal: carbsGoal,
                        progress: carbsProgress,
                        color: Theme.carbsColor
                    )

                    MacroProgressTile(
                        title: "Fat",
                        current: fat,
                        goal: fatGoal,
                        progress: fatProgress,
                        color: Theme.fatColor
                    )
                }
            }
        }
    }
}

private struct MacroProgressTile: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let current: Double
    let goal: Double
    let progress: Double
    let color: Color

    private var cappedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))

                Spacer()
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("\(Int(current))g")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("of \(Int(goal))g")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.quietText(colorScheme: colorScheme))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.cardBorder(colorScheme: colorScheme).opacity(0.65))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * cappedProgress)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Spacing.regular)
        .background(Theme.insetBackground(colorScheme: colorScheme).opacity(0.64))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius))
    }
}

#Preview {
    TodaysMacrosCard(
        protein: 120,
        carbs: 200,
        fat: 65,
        proteinGoal: 150,
        carbsGoal: 200,
        fatGoal: 65
    )
    .padding()
}
