//
//  WatchTheme.swift
//  LogCalWatch
//
//  Created by Antriksh Johri on 17/08/26.
//

import SwiftUI

/// Design system tokens optimized for watchOS OLED screens.
enum WatchTheme {
    static let primaryGreen = Color(red: 0.12, green: 0.55, blue: 0.35)
    static let primaryGreenGlow = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let accentBlue = Color(red: 0.18, green: 0.49, blue: 0.86)
    
    // Macro colors
    static let proteinColor = Color(red: 0.95, green: 0.38, blue: 0.38)
    static let carbsColor = Color(red: 0.95, green: 0.70, blue: 0.25)
    static let fatColor = Color(red: 0.30, green: 0.75, blue: 0.95)
    static let fiberColor = Color(red: 0.45, green: 0.75, blue: 0.40)
    
    // Backgrounds & surfaces
    static let pureBlack = Color.black
    static let cardBackground = Color(white: 0.12)
    static let cardBorder = Color(white: 0.22)
    static let insetBackground = Color(white: 0.08)
    
    // Typography colors
    static let primaryText = Color.white
    static let mutedText = Color(white: 0.65)
    static let quietText = Color(white: 0.45)
}
