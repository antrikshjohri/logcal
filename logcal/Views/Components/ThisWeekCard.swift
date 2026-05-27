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
                    Text("Weekly trend")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    
                    Spacer()
                    
                    Text("Total Calories")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                }
                
                WeeklyBarChartView(data: weeklyData, dailyGoal: dailyGoal)
                    .frame(height: 140)
            }
        }
    }
}
