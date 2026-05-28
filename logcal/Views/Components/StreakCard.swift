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
            VStack(alignment: .leading, spacing: 8) {
                // Flame Icon Circle
                ZStack {
                    Circle()
                        .fill(Theme.warningAmber.opacity(colorScheme == .dark ? 0.18 : 0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.warningAmber)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .lineLimit(1)
                    
                    Text("\(streak) days")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .lineLimit(1)
                    
                    Text("Keep it going!")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.warningAmber)
                        .padding(.top, 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
