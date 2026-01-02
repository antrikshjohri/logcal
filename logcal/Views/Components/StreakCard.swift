//
//  StreakCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct StreakCard: View {
    let streak: Int
    
    var body: some View {
        DashboardCard {
            VStack(spacing: Constants.Spacing.regular) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                
                Text("Streak")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.secondaryText)
                
                Text("\(streak)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("days")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

