//
//  MealPreviewCardView.swift
//  logcal
//

import SwiftUI

struct MealPreviewCardView: View {
    let preview: CompletedMealPreview
    let isFavorite: Bool
    var onLogMeal: (() -> Void)? = nil
    let onDismiss: () -> Void
    let onBookmark: () -> Void
    let onQuickEdit: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var quickEditPrompt: String = ""

    var body: some View {
        let result = preview.response

        VStack(alignment: .leading, spacing: 16) {
            // Header: Status, Meal Type, Bookmark, Dismiss
            HStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: 8) {
                    if preview.isPreviewOnly {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Preview")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(Theme.accentBlue)

                        Text("Not Logged")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accentBlue.opacity(0.12))
                            .foregroundColor(Theme.accentBlue)
                            .cornerRadius(6)
                    } else {
                        Text("Logged Successfully")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        
                        Text(result.mealType.capitalized)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.softAccentBackground(colorScheme: colorScheme))
                            .foregroundColor(Theme.primaryGreen)
                            .cornerRadius(6)
                    }
                }
                
                Spacer(minLength: 12)
                
                if !preview.isPreviewOnly {
                    Button(action: onBookmark) {
                        Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.primaryGreen)
                            .accessibilityLabel(isFavorite ? "Remove from favourites" : "Save meal")
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 16)
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Dismiss meal summary")
                }
                .buttonStyle(.plain)
            }

            // Food Title if present
            if !preview.foodText.isEmpty {
                Text(preview.foodText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    .lineLimit(2)
            }
            
            // Total Calories
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(result.totalCalories)) cal")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
            }
            
            // Macros Row
            if let macros = result.resolvedMealMacrosForDisplay() {
                let hasThreeDigits = macros.protein >= 100 || macros.carbs >= 100 || macros.fat >= 100 || (macros.fiber ?? 0) >= 100
                let fontSize: CGFloat = hasThreeDigits ? 9.5 : 10.5
                let horizontalPadding: CGFloat = hasThreeDigits ? 6.0 : 8.0
                let verticalPadding: CGFloat = hasThreeDigits ? 5.0 : 6.0
                let dotSize: CGFloat = hasThreeDigits ? 5.0 : 6.0
                
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Theme.proteinColor)
                            .frame(width: dotSize, height: dotSize)
                        Text("\(Int(macros.protein))g Protein")
                            .font(.system(size: fontSize, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            .lineLimit(1)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .background(Theme.proteinColor.opacity(0.12))
                    .cornerRadius(12)
                    
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Theme.carbsColor)
                            .frame(width: dotSize, height: dotSize)
                        Text("\(Int(macros.carbs))g Carbs")
                            .font(.system(size: fontSize, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            .lineLimit(1)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .background(Theme.carbsColor.opacity(0.12))
                    .cornerRadius(12)
                    
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Theme.fatColor)
                            .frame(width: dotSize, height: dotSize)
                        Text("\(Int(macros.fat))g Fat")
                            .font(.system(size: fontSize, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            .lineLimit(1)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .background(Theme.fatColor.opacity(0.12))
                    .cornerRadius(12)
                    
                    if let fiber = macros.fiber {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Theme.fiberColor)
                                .frame(width: dotSize, height: dotSize)
                            Text("\(Int(fiber))g Fiber")
                                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                .lineLimit(1)
                                .allowsTightening(true)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, verticalPadding)
                        .background(Theme.fiberColor.opacity(0.12))
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 4)
            }
            
            Divider()
                .background(Theme.cardBorder(colorScheme: colorScheme))
            
            Text("Items Breakdown")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
            
            ForEach(Array(result.items.enumerated()), id: \.offset) { index, item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.name)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        Spacer()
                        Text("\(Int(item.calories)) cal")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryGreen)
                    }
                    
                    Text("\(item.quantity)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    
                    if let p = item.protein, let c = item.carbs, let f = item.fat {
                        MacrosCaptionLine(protein: p, carbs: c, fat: f, fiber: item.fiber, font: .system(size: 11, design: .rounded))
                            .padding(.top, 2)
                    }
                    
                    if let assumptions = item.assumptions, !assumptions.isEmpty {
                        Text("Assumptions: \(assumptions)")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                            .padding(.top, 2)
                    }
                }
                .padding(.vertical, 4)
                
                if index < result.items.count - 1 {
                    Divider()
                        .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                        .padding(.horizontal, 10)
                }
            }

            MealSourcesRow(sources: result.sources)

            if preview.isPreviewOnly, let onLogMeal = onLogMeal {
                Button(action: onLogMeal) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Log this Meal")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(24)
                    .shadow(color: Theme.primaryGreen.opacity(0.35), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }

            Divider()
                .background(Theme.cardBorder(colorScheme: colorScheme))
            
            QuickEditMealSection(
                prompt: $quickEditPrompt,
                isLoading: preview.isRefining,
                errorMessage: preview.refineError
            ) {
                let text = quickEditPrompt
                onQuickEdit(text)
                quickEditPrompt = ""
            }
        }
        .padding(16)
        .background(Theme.cardBackground(colorScheme: colorScheme))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
        )
        .padding(.horizontal)
        .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.5), radius: 6, x: 0, y: 3)
        .onAppear {
            AnalyticsService.trackMealSummaryViewed()
        }
    }
}
