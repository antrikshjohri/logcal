//
//  WeeklyBarChartView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct WeeklyBarChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    let data: [WeeklyDayNutrientData]
    let nutrient: WeeklyTrendNutrient
    let goal: Double
    
    private var chartMax: Double {
        let maxVal = data.map { $0.value(for: nutrient) }.max() ?? 0
        return max(maxVal, goal, 10.0) * 1.25
    }
    
    private func barColor(for item: WeeklyDayNutrientData) -> Color {
        let val = item.value(for: nutrient)
        let baseColor = (nutrient == .calories && goal > 0 && val > goal) ? Theme.dangerRed : nutrient.color(colorScheme: colorScheme)
        if item.isToday {
            return baseColor
        }
        return baseColor.opacity(colorScheme == .dark ? 0.7 : 0.55)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dotted Goal Line
            if goal > 0 {
                GeometryReader { chartGeo in
                    let chartHeight = chartGeo.size.height
                    let yPos = chartHeight * (1.0 - CGFloat(goal / chartMax))
                    
                    ZStack(alignment: .leading) {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: yPos))
                            path.addLine(to: CGPoint(x: chartGeo.size.width - 45, y: yPos))
                        }
                        .stroke(
                            Theme.mutedText(colorScheme: colorScheme).opacity(0.35),
                            style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [4, 4])
                        )
                        
                        Text(formatValue(goal))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .frame(width: 42, alignment: .trailing)
                            .position(x: chartGeo.size.width - 20, y: yPos)
                    }
                }
                .frame(height: 80)
                .padding(.bottom, 24)
            }
            
            // HStack of bars
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(data) { item in
                    let val = item.value(for: nutrient)
                    VStack(spacing: 0) {
                        Text(formatValue(val))
                            .font(.system(size: 10, weight: item.isToday ? .bold : .medium, design: .rounded))
                            .foregroundColor(item.isToday ? Theme.primaryText(colorScheme: colorScheme) : Theme.mutedText(colorScheme: colorScheme))
                            .frame(height: 14)
                            .padding(.bottom, 4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        GeometryReader { barGeo in
                            VStack {
                                Spacer()
                                
                                Capsule()
                                    .fill(barColor(for: item))
                                    .frame(width: 16, height: max(CGFloat(val / chartMax) * barGeo.size.height, 6))
                                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: val)
                            }
                            .frame(width: barGeo.size.width, height: barGeo.size.height)
                        }
                        .frame(height: 80)
                        
                        Text(item.day)
                            .font(.system(size: 12, weight: item.isToday ? .bold : .medium, design: .rounded))
                            .foregroundColor(item.isToday ? Theme.primaryText(colorScheme: colorScheme) : Theme.mutedText(colorScheme: colorScheme))
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
    
    private func formatValue(_ number: Double) -> String {
        if nutrient == .calories {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: Int(number))) ?? "\(Int(number))"
        } else {
            return "\(Int(number))g"
        }
    }
}
