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
            HStack(spacing: 12) {
                // Flame Icon Circle
                ZStack {
                    Circle()
                        .fill(Theme.warningAmber.opacity(colorScheme == .dark ? 0.18 : 0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.warningAmber)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Streak")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .lineLimit(1)
                    
                    Text("\(streak) days")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .lineLimit(1)
                    
                    Text("Keep it going!")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.warningAmber)
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
