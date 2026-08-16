//
//  AppTheme.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import AppIntents
import Foundation

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Design Tokens
struct Theme {
    static func backgroundColor(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBackground : lightBackground
    }

    static func cardBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkCard : lightCard
    }

    static func elevatedCardBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkElevatedCard : lightElevatedCard
    }

    static func heroCardBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkHeroCard : lightHeroCard
    }

    static func insetBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkInset : lightInset
    }

    static func cardBorder(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBorder : lightBorder
    }

    static func primaryText(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkPrimaryText : lightPrimaryText
    }

    static func mutedText(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkSecondaryText : lightSecondaryText
    }

    static func quietText(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkTertiaryText : lightTertiaryText
    }

    static func softAccentBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? primaryGreen.opacity(0.18) : primaryGreen.opacity(0.1)
    }

    static func shadowColor(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.28) : Color.black.opacity(0.06)
    }

    static let primaryGreen = Color(red: 0.11, green: 0.45, blue: 0.28)
    static let mintGreen = Color(red: 0.45, green: 0.78, blue: 0.58)
    static let warningAmber = Color(red: 0.83, green: 0.48, blue: 0.12)
    static let dangerRed = Color(red: 0.78, green: 0.20, blue: 0.18)
    static let proteinColor = Color(red: 0.11, green: 0.45, blue: 0.28)
    static let carbsColor = Color(red: 0.79, green: 0.55, blue: 0.18)
    static let fatColor = Color(red: 0.85, green: 0.60, blue: 0.10)
    static let fiberColor = Color(red: 0.47, green: 0.53, blue: 0.23) // Warm Olive

    // Compatibility aliases while the rest of the app is migrated screen by screen.
    static let accentBlue = primaryGreen
    static let secondaryText = Color.secondary

    private static let lightBackground = Color(red: 0.96, green: 0.95, blue: 0.91)
    private static let lightCard = Color(red: 1.0, green: 0.99, blue: 0.96)
    private static let lightElevatedCard = Color.white
    private static let lightHeroCard = Color(red: 0.93, green: 0.97, blue: 0.90)
    private static let lightInset = Color(red: 0.95, green: 0.94, blue: 0.88)
    private static let lightBorder = Color(red: 0.80, green: 0.78, blue: 0.68).opacity(0.45)
    private static let lightPrimaryText = Color(red: 0.12, green: 0.15, blue: 0.12)
    private static let lightSecondaryText = Color(red: 0.39, green: 0.43, blue: 0.37)
    private static let lightTertiaryText = Color(red: 0.58, green: 0.60, blue: 0.53)

    private static let darkBackground = Color(red: 0.04, green: 0.08, blue: 0.06)
    private static let darkCard = Color(red: 0.08, green: 0.13, blue: 0.10)
    private static let darkElevatedCard = Color(red: 0.11, green: 0.17, blue: 0.13)
    private static let darkHeroCard = Color(red: 0.09, green: 0.18, blue: 0.12)
    private static let darkInset = Color(red: 0.05, green: 0.11, blue: 0.08)
    private static let darkBorder = Color(red: 0.43, green: 0.65, blue: 0.50).opacity(0.22)
    private static let darkPrimaryText = Color(red: 0.93, green: 0.95, blue: 0.90)
    private static let darkSecondaryText = Color(red: 0.68, green: 0.75, blue: 0.66)
    private static let darkTertiaryText = Color(red: 0.48, green: 0.56, blue: 0.49)
}

struct LogShortcutIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Shortcut"
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Action")
    var action: String?
    
    @Parameter(title: "Meal Type")
    var mealType: String?
    
    init() {}
    
    init(action: String? = nil, mealType: String? = nil) {
        self.action = action
        self.mealType = mealType
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        print("DEBUG: [LogShortcutIntent] perform called. action=\(action ?? "nil"), mealType=\(mealType ?? "nil")")
        
        let urlString = "logcal://log"
        var queryItems: [URLQueryItem] = []
        if let action {
            queryItems.append(URLQueryItem(name: "action", value: action))
        }
        if let mealType {
            queryItems.append(URLQueryItem(name: "mealType", value: mealType))
        }
        
        var components = URLComponents(string: urlString)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        let destinationURL = components?.url ?? URL(string: "logcal://dashboard")!
        print("DEBUG: [LogShortcutIntent] generated destination URL: \(destinationURL.absoluteString)")
        
        // Open URL dynamically to avoid extension target compilation warnings/errors
        if let applicationClass = NSClassFromString("UIApplication") as? NSObject.Type {
            let sharedSelector = NSSelectorFromString("sharedApplication")
            if applicationClass.responds(to: sharedSelector) {
                let sharedApplication = applicationClass.perform(sharedSelector).takeUnretainedValue()
                let openSelector = NSSelectorFromString("openURL:options:completionHandler:")
                if sharedApplication.responds(to: openSelector) {
                    print("DEBUG: [LogShortcutIntent] calling UIApplication openURL:options:completionHandler: with: \(destinationURL.absoluteString)")
                    
                    typealias OpenSignature = @convention(c) (AnyObject, Selector, NSURL, NSDictionary, (@convention(block) (Bool) -> Void)?) -> Void
                    let method = sharedApplication.method(for: openSelector)
                    let openBlock = unsafeBitCast(method, to: OpenSignature.self)
                    openBlock(sharedApplication, openSelector, destinationURL as NSURL, [:] as NSDictionary, nil)
                } else {
                    print("ERROR: [LogShortcutIntent] UIApplication shared does not respond to openURL:options:completionHandler:")
                }
            } else {
                print("ERROR: [LogShortcutIntent] UIApplication does not respond to sharedApplication")
            }
        } else {
            print("ERROR: [LogShortcutIntent] NSClassFromString('UIApplication') returned nil")
        }
        
        return .result()
    }
}

