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
            HStack(spacing: 12) {
                // Target Icon Circle
                ZStack {
                    Circle()
                        .fill(Theme.softAccentBackground(colorScheme: colorScheme))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "target")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.primaryGreen)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Goal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .lineLimit(1)
                    
                    Text("\(Int(goal)) cal")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .lineLimit(1)
                    
                    HStack(spacing: 2) {
                        Text("Edit goal")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.primaryGreen)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.primaryGreen)
                    }
                    .padding(.top, 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
