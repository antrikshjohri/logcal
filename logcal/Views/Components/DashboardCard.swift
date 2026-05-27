//
//  DashboardCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct DashboardCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Constants.Spacing.extraLarge)
            .background(Theme.cardBackground(colorScheme: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
            )
            .cornerRadius(Constants.Sizes.cornerRadius)
            .shadow(color: Theme.shadowColor(colorScheme: colorScheme), radius: 18, x: 0, y: 10)
    }
}
