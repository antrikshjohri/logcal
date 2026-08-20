//
//  ThisWeekCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

enum WeeklyTrendNutrient: String, CaseIterable, Identifiable {
    case calories = "Calories"
    case protein = "Protein"
    case carbs = "Carbs"
    case fat = "Fats"
    case fiber = "Fiber"
    
    var id: String { rawValue }
    var title: String { rawValue }
    
    var unit: String {
        self == .calories ? "cal" : "g"
    }
    
    func color(colorScheme: ColorScheme) -> Color {
        switch self {
        case .calories: return Theme.primaryGreen
        case .protein: return Color(red: 0.95, green: 0.38, blue: 0.38) // Rose Red
        case .carbs: return Color(red: 0.95, green: 0.70, blue: 0.25) // Amber Gold
        case .fat: return Color(red: 0.30, green: 0.75, blue: 0.95) // Sky Blue
        case .fiber: return Color(red: 0.20, green: 0.78, blue: 0.55) // Emerald
        }
    }
}

struct WeeklyDayNutrientData: Identifiable {
    let id = UUID()
    let day: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let isToday: Bool
    
    func value(for nutrient: WeeklyTrendNutrient) -> Double {
        switch nutrient {
        case .calories: return calories
        case .protein: return protein
        case .carbs: return carbs
        case .fat: return fat
        case .fiber: return fiber
        }
    }
}

struct ThisWeekCard: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let weeklyData: [WeeklyDayNutrientData]
    let dailyGoal: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double
    let fiberGoal: Double
    
    @State private var selectedNutrient: WeeklyTrendNutrient = .calories
    @State private var showNutrientDropdown: Bool = false
    
    private var currentGoal: Double {
        switch selectedNutrient {
        case .calories: return dailyGoal
        case .protein: return proteinGoal
        case .carbs: return carbsGoal
        case .fat: return fatGoal
        case .fiber: return fiberGoal
        }
    }
    
    private var weeklyAverage: Double {
        guard !weeklyData.isEmpty else { return 0 }
        let total = weeklyData.reduce(0.0) { $0 + $1.value(for: selectedNutrient) }
        return total / Double(weeklyData.count)
    }
    
    private var formattedAverage: String {
        if selectedNutrient == .calories {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let numStr = formatter.string(from: NSNumber(value: Int(weeklyAverage))) ?? "\(Int(weeklyAverage))"
            return "\(numStr) kcal / day"
        } else {
            return "\(Int(weeklyAverage))g / day"
        }
    }
    
    private var formattedGoal: String {
        if selectedNutrient == .calories {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let numStr = formatter.string(from: NSNumber(value: Int(currentGoal))) ?? "\(Int(currentGoal))"
            return "\(numStr) kcal"
        } else {
            return "\(Int(currentGoal))g"
        }
    }
    
    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                // Row 1: Weekly trend title & Custom Dropdown on the same line
                HStack(alignment: .center) {
                    Text("Weekly trend")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    
                    Spacer()
                    
                    // Custom Dropdown Trigger Button (Identical to HomeView meal type dropdown)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNutrientDropdown.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedNutrient.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .lineLimit(1)
                            Image(systemName: showNutrientDropdown ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(selectedNutrient.color(colorScheme: colorScheme))
                        .frame(width: 96, height: 28)
                        .background(selectedNutrient.color(colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.2 : 0.12))
                        .clipShape(Capsule())
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .zIndex(10)
                .overlay(alignment: .topTrailing) {
                    if showNutrientDropdown {
                        VStack(spacing: 0) {
                            ForEach(Array(WeeklyTrendNutrient.allCases.enumerated()), id: \.element) { index, nutrient in
                                Button {
                                    selectedNutrient = nutrient
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showNutrientDropdown = false
                                    }
                                } label: {
                                    HStack {
                                        Text(nutrient.title)
                                            .font(.system(size: 13, weight: nutrient == selectedNutrient ? .bold : .medium, design: .rounded))
                                            .foregroundColor(
                                                nutrient == selectedNutrient
                                                ? nutrient.color(colorScheme: colorScheme)
                                                : Theme.primaryText(colorScheme: colorScheme)
                                            )
                                        Spacer()
                                        if nutrient == selectedNutrient {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(nutrient.color(colorScheme: colorScheme))
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                if index < WeeklyTrendNutrient.allCases.count - 1 {
                                    Divider()
                                        .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                        .padding(.horizontal, 8)
                                }
                            }
                        }
                        .frame(width: 135)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                        )
                        .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.8), radius: 14, x: 0, y: 6)
                        .offset(y: 34)
                        .zIndex(100)
                    }
                }
                
                // Row 2: 7-Day Average
                HStack(spacing: 4) {
                    Text("7-Day Avg:")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    Text(formattedAverage)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(selectedNutrient.color(colorScheme: colorScheme))
                }
                .padding(.top, -6)
                
                WeeklyBarChartView(
                    data: weeklyData,
                    nutrient: selectedNutrient,
                    goal: currentGoal
                )
                .frame(height: horizontalSizeClass == .regular ? 200 : 140)
            }
        }
    }
}
