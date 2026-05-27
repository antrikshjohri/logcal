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
    
    private var chartMax: Double {
        let maxVal = data.map { $0.calories }.max() ?? 0
        return max(maxVal, dailyGoal) * 1.25
    }
    
    private func barColor(for dayData: (day: String, calories: Double, isToday: Bool)) -> Color {
        let baseColor = dayData.calories > dailyGoal ? Theme.dangerRed : Theme.primaryGreen
        if dayData.isToday {
            return baseColor
        }
        return baseColor.opacity(colorScheme == .dark ? 0.7 : 0.55)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dotted Goal Line
            GeometryReader { chartGeo in
                let chartHeight = chartGeo.size.height
                let yPos = chartHeight * (1.0 - CGFloat(dailyGoal / chartMax))
                
                ZStack(alignment: .leading) {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: yPos))
                        path.addLine(to: CGPoint(x: chartGeo.size.width - 45, y: yPos))
                    }
                    .stroke(
                        Theme.mutedText(colorScheme: colorScheme).opacity(0.35),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [4, 4])
                    )
                    
                    Text(formatNumber(dailyGoal))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .frame(width: 40, alignment: .trailing)
                        .position(x: chartGeo.size.width - 20, y: yPos)
                }
            }
            .frame(height: 80)
            .padding(.bottom, 24)
            
            // HStack of bars
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, dayData in
                    VStack(spacing: 0) {
                        Text(dayData.calories > 0 ? formatNumber(dayData.calories) : "0")
                            .font(.system(size: 10, weight: dayData.isToday ? .bold : .medium))
                            .foregroundColor(dayData.isToday ? Theme.primaryText(colorScheme: colorScheme) : Theme.mutedText(colorScheme: colorScheme))
                            .frame(height: 14)
                            .padding(.bottom, 4)
                        
                        GeometryReader { barGeo in
                            VStack {
                                Spacer()
                                
                                Capsule()
                                    .fill(barColor(for: dayData))
                                    .frame(width: 16, height: max(CGFloat(dayData.calories / chartMax) * barGeo.size.height, 6))
                            }
                            .frame(width: barGeo.size.width, height: barGeo.size.height)
                        }
                        .frame(height: 80)
                        
                        Text(dayData.day)
                            .font(.system(size: 12, weight: dayData.isToday ? .bold : .medium))
                            .foregroundColor(dayData.isToday ? Theme.primaryText(colorScheme: colorScheme) : Theme.mutedText(colorScheme: colorScheme))
                            .frame(height: 16)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Trailing margin to offset Sunday from the dotted line label
                Spacer()
                    .frame(width: 35)
            }
        }
    }
    
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(number))) ?? "\(Int(number))"
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
