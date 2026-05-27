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
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
            .padding(.bottom, 6)
            
            // Protein Row
            MacroRow(
                title: "Protein",
                current: protein,
                goal: proteinGoal,
                progress: proteinProgress,
                color: Theme.proteinColor,
                percentColor: Theme.proteinColor
            )
            
            Divider()
                .background(Theme.cardBorder(colorScheme: colorScheme))
            
            // Carbs Row
            MacroRow(
                title: "Carbs",
                current: carbs,
                goal: carbsGoal,
                progress: carbsProgress,
                color: Theme.carbsColor,
                percentColor: Theme.carbsColor
            )
            
            Divider()
                .background(Theme.cardBorder(colorScheme: colorScheme))
            
            // Fat Row
            MacroRow(
                title: "Fat",
                current: fat,
                goal: fatGoal,
                progress: fatProgress,
                color: Theme.fatColor,
                percentColor: Theme.fatColor
            )
        }
        .padding(Constants.Spacing.extraLarge)
        .background(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .fill(Theme.cardBackground(colorScheme: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
        )
        .shadow(color: Theme.shadowColor(colorScheme: colorScheme), radius: 18, x: 0, y: 10)
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
        HStack(spacing: Constants.Spacing.regular) {
            // Left: Circular progress ring with value inside
            ZStack {
                Circle()
                    .stroke(color.opacity(colorScheme == .dark ? 0.15 : 0.1), lineWidth: 4.5)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: cappedProgress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: -2) {
                    Text("\(Int(current))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    
                    Text("g")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                }
            }
            
            // Middle: Title, target values, and linear progress bar
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                
                Text("\(Int(current)) / \(Int(goal)) g")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                
                // Linear Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: geometry.size.width * cappedProgress)
                    }
                }
                .frame(height: 6)
            }
            .padding(.leading, 4)
            
            Spacer(minLength: 8)
            
            // Right: Percentage only (no chevron)
            HStack(spacing: Constants.Spacing.small) {
                Text("\(percentage)%")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(percentColor)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TodaysMacrosCard(
        protein: 120,
        carbs: 200,
        fat: 65,
        proteinGoal: 150,
        carbsGoal: 200,
        fatGoal: 65
    )
    .padding()
}
