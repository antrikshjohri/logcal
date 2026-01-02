//
//  SettingsRow.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

// Reusable content for settings row (used in both button and NavigationLink)
struct SettingsRowContent: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let trailingValue: String?
    
    init(icon: String, iconColor: Color = Theme.secondaryText, title: String, trailingValue: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.trailingValue = trailingValue
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.regular) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            // Title
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Trailing value (if provided)
            if let value = trailingValue {
                Text(value)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Theme.secondaryText)
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.secondaryText)
        }
        .padding(Constants.Spacing.large)
        .background(Theme.cardBackground(colorScheme: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
        )
        .cornerRadius(Constants.Sizes.largeCornerRadius)
    }
}

// Button version for actions (like Theme selector)
struct SettingsRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let trailingValue: String?
    let action: () -> Void
    
    init(icon: String, iconColor: Color = Theme.secondaryText, title: String, trailingValue: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.trailingValue = trailingValue
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            SettingsRowContent(icon: icon, iconColor: iconColor, title: title, trailingValue: trailingValue)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: Constants.Spacing.regular) {
        SettingsRow(icon: "target", iconColor: Theme.accentBlue, title: "Daily Goal", trailingValue: "2,000 cal") {
            print("Tapped")
        }
        SettingsRow(icon: "paintpalette", title: "Theme", trailingValue: "Dark") {
            print("Tapped")
        }
    }
    .padding()
    .background(Theme.backgroundColor(colorScheme: .dark))
}
