//
//  ProfileCard.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct ProfileCard: View {
    @Environment(\.colorScheme) var colorScheme
    let name: String
    let email: String
    let onEditProfile: () -> Void
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            HStack(spacing: Constants.Spacing.large) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Theme.accentBlue)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                
                // Name and email
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    Text(name)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(email)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Theme.secondaryText)
                }
                
                Spacer()
            }
            
            // Edit Profile button
            SecondaryButton(title: "Edit Profile", action: onEditProfile)
        }
        .padding(Constants.Spacing.extraLarge)
        .background(Theme.cardBackground(colorScheme: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
        )
        .cornerRadius(Constants.Sizes.largeCornerRadius)
    }
}

#Preview {
    ProfileCard(name: "Antriksh Johri", email: "antriksh@example.com") {
        print("Edit Profile")
    }
    .padding()
    .background(Theme.backgroundColor(colorScheme: .dark))
}

