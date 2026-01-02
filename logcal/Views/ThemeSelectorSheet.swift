//
//  ThemeSelectorSheet.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct ThemeSelectorSheet: View {
    @Environment(\.colorScheme) var systemColorScheme
    @AppStorage("appTheme") private var appThemeString: String = AppTheme.system.rawValue
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: appThemeString) ?? .system
    }
    
    // Compute effective color scheme based on selected theme
    private var effectiveColorScheme: ColorScheme {
        switch selectedTheme {
        case .system:
            return systemColorScheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Choose Theme")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, Constants.Spacing.extraLarge)
            .padding(.top, Constants.Spacing.extraLarge)
            .padding(.bottom, Constants.Spacing.large)
            
            // Theme options - wrapped in a card
            VStack(spacing: 0) {
                ThemeRow(
                    theme: .system,
                    isSelected: selectedTheme == .system,
                    colorScheme: effectiveColorScheme
                ) {
                    print("DEBUG: System theme selected")
                    appThemeString = AppTheme.system.rawValue
                }
                
                Divider()
                    .background(Theme.cardBorder(colorScheme: effectiveColorScheme))
                    .padding(.leading, Constants.Spacing.large)
                
                ThemeRow(
                    theme: .light,
                    isSelected: selectedTheme == .light,
                    colorScheme: effectiveColorScheme
                ) {
                    print("DEBUG: Light theme selected")
                    appThemeString = AppTheme.light.rawValue
                }
                
                Divider()
                    .background(Theme.cardBorder(colorScheme: effectiveColorScheme))
                    .padding(.leading, Constants.Spacing.large)
                
                ThemeRow(
                    theme: .dark,
                    isSelected: selectedTheme == .dark,
                    colorScheme: effectiveColorScheme
                ) {
                    print("DEBUG: Dark theme selected")
                    appThemeString = AppTheme.dark.rawValue
                }
            }
            .background(Theme.cardBackground(colorScheme: effectiveColorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                    .stroke(Theme.cardBorder(colorScheme: effectiveColorScheme), lineWidth: Constants.Sizes.borderWidth)
            )
            .cornerRadius(Constants.Sizes.largeCornerRadius)
            .padding(.horizontal, Constants.Spacing.extraLarge)
            
            // Footer text
            Text("System theme follows your device settings.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Theme.secondaryText)
                .padding(.top, Constants.Spacing.large)
                .padding(.horizontal, Constants.Spacing.extraLarge)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(sheetBackgroundColor(colorScheme: effectiveColorScheme))
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(selectedTheme.colorScheme)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(sheetBackgroundColor(colorScheme: effectiveColorScheme))
    }
    
    // Sheet background with better contrast in dark mode
    private func sheetBackgroundColor(colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            // Slightly lighter than pure black for better separation, fully opaque
            return Color(white: 0.1).opacity(1.0)
        } else {
            // Fully opaque white background for light mode
            return Color(.systemGroupedBackground).opacity(1.0)
        }
    }
}

// Separate row component for better tap handling
struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(theme.displayName)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.accentBlue)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.horizontal, Constants.Spacing.large)
            .padding(.vertical, Constants.Spacing.regular)
            .contentShape(Rectangle())
            .background(isSelected ? Theme.accentBlue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ThemeSelectorSheet()
}
