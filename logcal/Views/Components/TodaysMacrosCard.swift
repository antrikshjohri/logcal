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
    
    /// Progress ratio (can exceed 1.0 for display %). Ring draws up to 100%.
    private var proteinProgress: Double {
        proteinGoal > 0 ? protein / proteinGoal : 0
    }
    
    private var carbsProgress: Double {
        carbsGoal > 0 ? carbs / carbsGoal : 0
    }
    
    private var fatProgress: Double {
        fatGoal > 0 ? fat / fatGoal : 0
    }
    
    /// Protein: over goal = green. Carbs/Fat: over goal = red.
    private func ringColor(macro: String, progress: Double) -> Color {
        let exceeded = progress >= 1.0
        switch macro {
        case "protein": return exceeded ? .green : Theme.accentBlue
        case "carbs", "fat": return exceeded ? .red : Theme.accentBlue
        default: return Theme.accentBlue
        }
    }
    
    var body: some View {
        DashboardCard {
            VStack(spacing: Constants.Spacing.large) {
                // Header
                HStack {
                    Text("Today's Macros")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.secondaryText)
                }
                
                // Macros content
                HStack(spacing: Constants.Spacing.regular) {
                    // Protein
                    VStack(spacing: Constants.Spacing.small) {
                        Text("\(Int(protein))g")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Protein")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Theme.secondaryText)
                        ProgressRingView(progress: proteinProgress, size: 60, ringColor: ringColor(macro: "protein", progress: proteinProgress))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Carbs
                    VStack(spacing: Constants.Spacing.small) {
                        Text("\(Int(carbs))g")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Carbs")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Theme.secondaryText)
                        ProgressRingView(progress: carbsProgress, size: 60, ringColor: ringColor(macro: "carbs", progress: carbsProgress))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Fat
                    VStack(spacing: Constants.Spacing.small) {
                        Text("\(Int(fat))g")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Fat")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Theme.secondaryText)
                        ProgressRingView(progress: fatProgress, size: 60, ringColor: ringColor(macro: "fat", progress: fatProgress))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
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
