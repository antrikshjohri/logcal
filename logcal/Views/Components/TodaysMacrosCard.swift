//
//  TodaysMacrosCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct TodaysMacrosCard: View {
    @Environment(\.colorScheme) var colorScheme
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double
    let fiberGoal: Double
    var onDetailsTapped: (() -> Void)? = nil
    
    private var proteinProgress: Double {
        proteinGoal > 0 ? protein / proteinGoal : 0
    }
    
    private var carbsProgress: Double {
        carbsGoal > 0 ? carbs / carbsGoal : 0
    }
    
    private var fatProgress: Double {
        fatGoal > 0 ? fat / fatGoal : 0
    }
    
    private var fiberProgress: Double {
        fiberGoal > 0 ? fiber / fiberGoal : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("Macros")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                
                Spacer()
                
                Button(action: {
                    onDetailsTapped?()
                }) {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Theme.primaryGreen)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 2)
            
            // Protein Row
            MacroRow(
                title: "Protein",
                current: protein,
                goal: proteinGoal,
                progress: proteinProgress,
                color: Theme.proteinColor,
                percentColor: Theme.proteinColor
            )
            
            // Carbs Row
            MacroRow(
                title: "Carbs",
                current: carbs,
                goal: carbsGoal,
                progress: carbsProgress,
                color: Theme.carbsColor,
                percentColor: Theme.carbsColor
            )
            
            // Fat Row
            MacroRow(
                title: "Fat",
                current: fat,
                goal: fatGoal,
                progress: fatProgress,
                color: Theme.fatColor,
                percentColor: Theme.fatColor
            )
            
            // Fiber Row
            MacroRow(
                title: "Fiber",
                current: fiber,
                goal: fiberGoal,
                progress: fiberProgress,
                color: Theme.fiberColor,
                percentColor: Theme.fiberColor
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .fill(Theme.cardBackground(colorScheme: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
        )
        .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

private struct MacroRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let current: Double
    let goal: Double
    let progress: Double
    let color: Color
    let percentColor: Color
    
    private var percentage: Int {
        goal > 0 ? Int(round(progress * 100)) : 0
    }
    
    private var cappedProgress: Double {
        min(max(progress, 0), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(Int(current))/\(Int(goal))g")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    
                    Text("\(percentage)%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(percentColor)
                }
            }
            
            // Linear Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
                    
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(color)
                        .frame(width: geometry.size.width * cappedProgress)
                }
            }
            .frame(height: 7)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    TodaysMacrosCard(
        protein: 120,
        carbs: 200,
        fat: 65,
        fiber: 25,
        proteinGoal: 150,
        carbsGoal: 200,
        fatGoal: 65,
        fiberGoal: 28
    )
    .padding()
}
