//
//  WeeklyBarChartView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct WeeklyBarChartView: View {
    let data: [(day: String, calories: Double, isToday: Bool)]
    
    private var maxCalories: Double {
        let max = data.map { $0.calories }.max() ?? 1
        return max > 0 ? max : 1 // Avoid division by zero
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: Constants.Spacing.regular) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, dayData in
                VStack(spacing: Constants.Spacing.small) {
                    // Bar
                    GeometryReader { geometry in
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(dayData.isToday ? Theme.accentBlue : Theme.secondaryText.opacity(0.3))
                                .frame(height: max(geometry.size.height * (dayData.calories / maxCalories), 4))
                        }
                    }
                    
                    // Day label
                    Text(dayData.day)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.secondaryText)
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
    ])
    .frame(height: 120)
    .padding()
}

