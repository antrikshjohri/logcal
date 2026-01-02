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
    let remaining: Double
    let progress: Double
    
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
                    
                    // Right: Progress ring
                    ProgressRingView(progress: progress)
                }
                
                // Divider
                Divider()
                    .background(Theme.cardBorder(colorScheme: colorScheme))
                
                // Bottom: Remaining
                HStack {
                    Text("Remaining")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Theme.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(remaining)) cal")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.accentBlue)
                }
            }
        }
    }
}

