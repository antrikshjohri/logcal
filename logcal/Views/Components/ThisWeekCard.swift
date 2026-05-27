//
//  ThisWeekCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct ThisWeekCard: View {
    @Environment(\.colorScheme) var colorScheme
    let weeklyData: [(day: String, calories: Double, isToday: Bool)]
    let weeklyAverage: Double
    let dailyGoal: Double
    
    var body: some View {
        DashboardCard {
            VStack(spacing: Constants.Spacing.large) {
                // Header
                HStack {
                    Text("This Week")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    
                    Spacer()
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                }
                
                WeeklyBarChartView(data: weeklyData, dailyGoal: dailyGoal)
                    .frame(height: 130)
                
                Divider()
                    .background(Theme.cardBorder(colorScheme: colorScheme))
                
                HStack {
                    Text("Weekly Average")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    
                    Spacer()
                    
                    Text("\(Int(weeklyAverage)) cal")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                }
            }
        }
    }
}
