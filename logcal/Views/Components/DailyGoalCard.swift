//
//  DailyGoalCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct DailyGoalCard: View {
    let goal: Double
    
    var body: some View {
        DashboardCard {
            VStack(spacing: Constants.Spacing.regular) {
                Image(systemName: "target")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.accentBlue)
                
                Text("Daily Goal")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
                
                Text("\(Int(goal))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("calories")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

