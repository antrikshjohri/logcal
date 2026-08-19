//
//  ConnectHealthDiscoveryCard.swift
//  logcal
//
//  Created by Antriksh Johri on 20/08/26.
//

import SwiftUI

struct ConnectHealthDiscoveryCard: View {
    @Environment(\.colorScheme) var colorScheme
    let onConnect: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(colorScheme == .dark ? 0.25 : 0.12))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Connect Apple Health")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.primaryGreen)
                                .clipShape(Capsule())
                        }
                        
                        Text("Apple Watch & Activity Sync")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                }
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .padding(6)
                        .background(Theme.insetBackground(colorScheme: colorScheme))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            Text("Sync your meals, track daily steps & Apple Watch workouts, and calculate net remaining calories.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                .lineSpacing(2)
            
            Button {
                onConnect()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .bold))
                    Text("Connect Apple Health")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Theme.primaryGreen)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .fill(Theme.cardBackground(colorScheme: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
        )
        .shadow(color: Theme.shadowColor(colorScheme: colorScheme), radius: 14, x: 0, y: 6)
    }
}
