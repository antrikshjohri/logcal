//
//  ErrorBanner.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct ErrorBanner: View {
    let title: String
    let message: String
    let type: BannerType
    
    enum BannerType {
        case error
        case warning
        
        var backgroundColor: Color {
            switch self {
            case .error:
                return Constants.Colors.errorBackground
            case .warning:
                return Constants.Colors.warningBackground
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .error:
                return Constants.Colors.primaryRed
            case .warning:
                return Color.orange
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(type.backgroundColor)
        .foregroundColor(type.foregroundColor)
        .cornerRadius(Constants.Sizes.cornerRadius)
        .padding(.horizontal)
    }
}

#Preview {
    VStack(spacing: 16) {
        ErrorBanner(
            title: "Error",
            message: "Failed to log meal. Please try again.",
            type: .error
        )
        
        ErrorBanner(
            title: "Speech Recognition Error",
            message: "Microphone permission denied",
            type: .warning
        )
    }
}

