//
//  WeeklyBarChartView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct WeeklyBarChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    let data: [(day: String, calories: Double, isToday: Bool)]
    let dailyGoal: Double
    
    // Calculate max calories with 20% padding above
    private var chartMax: Double {
        let max = data.map { $0.calories }.max() ?? 1
        return max > 0 ? max * 1.2 : 1 // Add 20% padding above max
    }
    
    private func barColor(for dayData: (day: String, calories: Double, isToday: Bool)) -> Color {
        if dayData.calories <= dailyGoal {
            return dayData.isToday ? Theme.primaryGreen : Theme.mintGreen.opacity(colorScheme == .dark ? 0.78 : 0.9)
        } else {
            return Theme.warningAmber.opacity(colorScheme == .dark ? 0.82 : 0.9)
        }
    }
    
    private func todayBorderColor(for dayData: (day: String, calories: Double, isToday: Bool)) -> Color {
        dayData.calories <= dailyGoal ? Theme.primaryGreen : Theme.warningAmber
    }
    
    // Format calories in compact form (e.g., 2.5k, 1.2k, 500)
    private func formatCalories(_ calories: Double) -> String {
        if calories >= 1000 {
            let kValue = calories / 1000
            if kValue.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(kValue))k"
            } else {
                return String(format: "%.1fk", kValue)
            }
        } else {
            return "\(Int(calories))"
        }
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: Constants.Spacing.regular) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, dayData in
                VStack(spacing: 0) {
                    if dayData.calories > 0 {
                        Text(formatCalories(dayData.calories))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                            .frame(height: 16)
                            .padding(.bottom, 4)
                    } else {
                        Spacer()
                            .frame(height: 20)
                    }
                    
                    // Bar container - separate from label
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(barColor(for: dayData))
                                .frame(height: max(geometry.size.height * (dayData.calories / chartMax), 4))
                                .shadow(color: barColor(for: dayData).opacity(0.18), radius: 7, x: 0, y: 4)
                                .overlay(
                                    Group {
                                        if dayData.isToday {
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(todayBorderColor(for: dayData), lineWidth: 2.5)
                                        }
                                    }
                                )
                        }
                    }
                    .frame(height: 80)
                    .padding(.bottom, 8)
                    
                    Text(dayData.day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(dayData.isToday ? Theme.primaryText(colorScheme: colorScheme) : Theme.mutedText(colorScheme: colorScheme))
                        .frame(height: 20)
                        .padding(.top, 4)
                }
            }
        }
    }
}

#Preview {
    WeeklyBarChartView(data: [
        ("M", 1800, false),
        ("T", 2200, false),
        ("W", 1900, false),
        ("T", 2100, false),
        ("F", 2000, false),
        ("S", 1850, false),
        ("T", 1795, true)
    ], dailyGoal: 2000)
    .frame(height: 120)
    .padding()
}
