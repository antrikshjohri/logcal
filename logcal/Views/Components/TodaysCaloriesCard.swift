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

    private var overBudgetAccent: Color {
        colorScheme == .dark ? Color(red: 1.0, green: 0.68, blue: 0.32) : Theme.warningAmber
    }

    private var statusText: String {
        isOverGoal ? "Over target" : "On track"
    }

    private var primaryAmount: Double {
        isOverGoal ? amountOverGoal : remainingUnderGoal
    }

    private var primaryLabel: String {
        isOverGoal ? "over your goal" : "cal remaining"
    }

    private var accentColor: Color {
        isOverGoal ? overBudgetAccent : Theme.primaryGreen
    }
    
    var body: some View {
        VStack(spacing: Constants.Spacing.extraLarge) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    Text("Calories")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))

                    Text("\(Int(primaryAmount))")
                        .font(.system(size: 58, weight: .bold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(primaryLabel)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                }

                Spacer(minLength: Constants.Spacing.large)

                VStack(alignment: .trailing, spacing: Constants.Spacing.regular) {
                    Text(statusText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, Constants.Spacing.regular)
                        .padding(.vertical, Constants.Spacing.small)
                        .background(accentColor.opacity(colorScheme == .dark ? 0.22 : 0.12))
                        .clipShape(Capsule())

                    ProgressRingView(
                        progress: progress,
                        size: 104,
                        ringColor: accentColor
                    )
                }
            }

            HStack(spacing: Constants.Spacing.regular) {
                CalorieMetricPill(
                    title: "Eaten",
                    value: "\(Int(calories))",
                    suffix: "cal"
                )

                CalorieMetricPill(
                    title: "Goal",
                    value: "\(Int(goal))",
                    suffix: "cal"
                )

                CalorieMetricPill(
                    title: isOverGoal ? "Over" : "Left",
                    value: "\(Int(primaryAmount))",
                    suffix: "cal",
                    valueColor: accentColor
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .fill(Theme.heroCardBackground(colorScheme: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
        )
        .shadow(color: Theme.shadowColor(colorScheme: colorScheme), radius: 24, x: 0, y: 14)
    }
}

private struct CalorieMetricPill: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let suffix: String
    var valueColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.quietText(colorScheme: colorScheme))

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(valueColor ?? Theme.primaryText(colorScheme: colorScheme))

                Text(suffix)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.Spacing.regular)
        .padding(.vertical, Constants.Spacing.medium)
        .background(Theme.insetBackground(colorScheme: colorScheme).opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius))
    }
}
