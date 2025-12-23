//
//  Constants.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import AVFoundation

enum Constants {
    // MARK: - API Configuration
    enum API {
        // Direct OpenAI (for development/fallback)
        static let baseURL = "https://api.openai.com/v1/chat/completions"
        static let model = "gpt-4o-2024-08-06"
        static let temperature: Double = 0.3
        
        // Firebase Functions (for production)
        static let useFirebase = true // Set to false to use direct OpenAI
    }
    
    // MARK: - UI Colors
    enum Colors {
        static let primaryBackground = Color.gray.opacity(0.1)
        static let secondaryBackground = Color.gray.opacity(0.1)
        static let errorBackground = Color.red.opacity(0.1)
        static let warningBackground = Color.orange.opacity(0.1)
        static let successBackground = Color.green.opacity(0.1)
        
        static let badgeBackground = Color.blue.opacity(0.2)
        static let micActiveBackground = Color.red.opacity(0.1)
        static let micInactiveBackground = Color.blue.opacity(0.1)
        
        static let borderGray = Color.gray.opacity(0.3)
        static let primaryBlue = Color.blue
        static let primaryRed = Color.red
        static let primaryGray = Color.gray
        static let secondaryGray = Color.secondary
    }
    
    // MARK: - UI Spacing
    enum Spacing {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let regular: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
    }
    
    // MARK: - UI Sizes
    enum Sizes {
        static let micIcon: CGFloat = 20
        static let emptyStateIcon: CGFloat = 50
        static let textEditorMinHeight: CGFloat = 100
        static let weightTextFieldWidth: CGFloat = 80
        static let cornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
    }
    
    // MARK: - Date Formats
    enum DateFormats {
        static let fullDate = "EEEE, MMMM d, yyyy"
        static let dateStyle: DateFormatter.Style = .medium
        static let timeStyle: DateFormatter.Style = .none
    }
    
    // MARK: - Locale
    enum Locale {
        static let speechRecognition = "en-US"
        static let timeZone = "Asia/Kolkata"
    }
    
    // MARK: - Meal Type Time Ranges (IST)
    enum MealTypeRanges {
        static let breakfast = 5...10
        static let lunch = 11...15
        static let snack = 16...18
        static let dinner = 19...23
        static let lateNightSnack = 0...4
    }
    
    // MARK: - Audio Configuration
    enum Audio {
        static let bufferSize: AVAudioFrameCount = 1024
    }
}

