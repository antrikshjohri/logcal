//
//  StreakCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct StreakCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let streak: Int
    
    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.mintGreen)
                        .frame(width: 34, height: 34)
                        .background(Theme.mintGreen.opacity(colorScheme == .dark ? 0.18 : 0.14))
                        .clipShape(Circle())

                    Spacer()
                }

                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    Text("Streak")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))

                    Text("\(streak)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))

                    Text("days")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
