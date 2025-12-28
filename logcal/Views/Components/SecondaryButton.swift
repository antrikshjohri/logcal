//
//  SecondaryButton.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct SecondaryButton: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.accentBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Theme.accentBlue.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(22) // Pill shape
        }
    }
}

#Preview {
    SecondaryButton(title: "Edit Profile") {
        print("Tapped")
    }
    .padding()
    .background(Theme.backgroundColor(colorScheme: .dark))
}

