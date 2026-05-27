//
//  DailyGoalCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct DailyGoalCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let goal: Double
    
    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.primaryGreen)
                        .frame(width: 34, height: 34)
                        .background(Theme.softAccentBackground(colorScheme: colorScheme))
                        .clipShape(Circle())

                    Spacer()
                }

                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    Text("Daily Goal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))

                    Text("\(Int(goal))")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text("calories")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
