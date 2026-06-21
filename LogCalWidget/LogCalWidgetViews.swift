//
//  LogCalWidgetViews.swift
//  LogCalWidget
//
//  Created by Antriksh Johri on 19/06/26.
//

import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Widget Theme Tokens

struct WidgetTheme {
    static let darkBackground = Color(red: 0.08, green: 0.13, blue: 0.10) // App's dark card token
    static let darkElevatedBackground = Color(red: 0.11, green: 0.17, blue: 0.13) // elevated surface
    
    // Macro colors
    static let calorieGreen = Theme.primaryGreen
    static let proteinGreen = Theme.proteinColor
    static let carbsBlue = Color(red: 0.12, green: 0.53, blue: 0.90) // bright electric blue
    static let fatOrange = Color(red: 0.93, green: 0.48, blue: 0.12) // bright orange
    static let fiberPurple = Color(red: 0.58, green: 0.30, blue: 0.90) // bright purple
    static let calorieExceededOrange = Color(red: 1.0, green: 0.68, blue: 0.32)
    
    // Track colors
    static let darkNeutralTrack = Color(red: 0.14, green: 0.18, blue: 0.16)
    
    // Text colors
    static let primaryText = Theme.primaryText(colorScheme: .dark)
    static let mutedText = Theme.mutedText(colorScheme: .dark)
    static let quietText = Theme.quietText(colorScheme: .dark)
}

// MARK: - Shared Views

struct WidgetProgressRing: View {
    let consumed: Double
    let goal: Double
    let size: CGFloat
    let strokeWidth: CGFloat
    let color: Color
    
    var progress: Double {
        goal > 0 ? min(max(consumed / goal, 0.0), 1.0) : 0.0
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(WidgetTheme.darkNeutralTrack, lineWidth: strokeWidth)
            
            if goal > 0 && progress > 0 {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: size, height: size)
    }
}

struct WidgetMacroRow: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color
    
    var progress: Double {
        goal > 0 ? min(max(value / goal, 0.0), 1.0) : 0.0
    }
    
    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(WidgetTheme.primaryText)
                
                Spacer()
                
                if goal > 0 {
                    HStack(spacing: 0) {
                        Text("\(Int(value))")
                            .foregroundColor(color)
                        Text(" / \(Int(goal))g")
                            .foregroundColor(WidgetTheme.mutedText)
                    }
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                } else {
                    Text("\(Int(value))g")
                        .font(.system(size: 11, weight: .semibold).monospacedDigit())
                        .foregroundColor(color)
                }
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(WidgetTheme.darkNeutralTrack)
                        .frame(height: 4)
                    
                    if progress > 0 {
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * CGFloat(progress), height: 4)
                    }
                }
            }
            .frame(height: 4)
        }
    }
}

struct WidgetMacroCell: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color
    
    var progress: Double {
        goal > 0 ? min(max(value / goal, 0.0), 1.0) : 0.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(WidgetTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Text("\(Int(value))g")
                    .font(.system(size: 9.5, weight: .bold).monospacedDigit())
                    .foregroundColor(color)
                    .lineLimit(1)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(WidgetTheme.darkNeutralTrack)
                        .frame(height: 3)
                    
                    if progress > 0 {
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * CGFloat(progress), height: 3)
                    }
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(WidgetTheme.darkElevatedBackground)
        )
    }
}

// MARK: - 1. Small Widget: Calories

struct CaloriesWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SimpleEntry
    
    var isOverGoal: Bool {
        entry.dailyGoal > 0 && entry.calories > entry.dailyGoal
    }
    
    var remaining: Int {
        Int(max(entry.dailyGoal - entry.calories, 0))
    }
    
    var overdue: Int {
        Int(max(entry.calories - entry.dailyGoal, 0))
    }
    
    var calorieRingColor: Color {
        isOverGoal ? WidgetTheme.calorieExceededOrange : WidgetTheme.calorieGreen
    }
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            WidgetProgressRing(
                consumed: entry.calories,
                goal: entry.dailyGoal,
                size: 50,
                strokeWidth: 5,
                color: .primary
            )
            .overlay(
                VStack(spacing: -2) {
                    Text("\(isOverGoal ? overdue : remaining)")
                        .font(.system(size: 13, weight: .bold).monospacedDigit())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(isOverGoal ? "over" : "left")
                        .font(.system(size: 8, weight: .semibold))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                }
            )
            .containerBackground(for: .widget) {}
            .widgetURL(URL(string: "logcal://dashboard"))
            
        case .accessoryInline:
            HStack(spacing: 3) {
                Image(systemName: "leaf.fill")
                Text("\(isOverGoal ? overdue : remaining) cal \(isOverGoal ? "overdue" : "left")")
            }
            .containerBackground(for: .widget) {}
            .widgetURL(URL(string: "logcal://dashboard"))
            
        default:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                
                WidgetProgressRing(
                    consumed: entry.calories,
                    goal: entry.dailyGoal,
                    size: 90,
                    strokeWidth: 9,
                    color: calorieRingColor
                )
                .overlay(
                    VStack(spacing: -1) {
                        Text("\(Int(entry.calories))")
                            .font(.system(size: 22, weight: .bold).monospacedDigit())
                            .foregroundColor(WidgetTheme.primaryText)
                        Text("cal")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(WidgetTheme.mutedText)
                    }
                )
                
                Spacer(minLength: 0)
                
                if entry.dailyGoal > 0 {
                    VStack(spacing: 2) {
                        if isOverGoal {
                            HStack(spacing: 3) {
                                Text("\(overdue)")
                                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                                    .foregroundColor(WidgetTheme.calorieExceededOrange)
                                Text("cal overdue")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(WidgetTheme.calorieExceededOrange)
                            }
                        } else {
                            HStack(spacing: 3) {
                                Text("\(remaining)")
                                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                                    .foregroundColor(WidgetTheme.calorieGreen)
                                Text("cal left")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(WidgetTheme.primaryText)
                            }
                        }
                        
                        Text("of \(Int(entry.dailyGoal)) cal")
                            .font(.system(size: 9.5, weight: .regular))
                            .foregroundColor(WidgetTheme.quietText)
                    }
                } else {
                    Text("No goal set")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(WidgetTheme.quietText)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(WidgetTheme.darkBackground, for: .widget)
            .widgetURL(URL(string: "logcal://dashboard"))
        }
    }
}

// MARK: - 2. Small Widget: Macros

struct MacrosWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: SimpleEntry
    
    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 4) {
                // Calorie Progress Row
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Calories")
                            .foregroundColor(.secondary)
                        Spacer()
                        if entry.dailyGoal > 0 {
                            Text("\(Int(entry.calories)) / \(Int(entry.dailyGoal)) cal")
                                .bold()
                        } else {
                            Text("\(Int(entry.calories)) cal")
                                .bold()
                        }
                    }
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    
                    if entry.dailyGoal > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.15))
                                if entry.calories > 0 {
                                    let progress = min(max(entry.calories / entry.dailyGoal, 0.0), 1.0)
                                    Capsule()
                                        .fill(Color.primary)
                                        .frame(width: geo.size.width * CGFloat(progress))
                                }
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .padding(.bottom, 1)
                
                // Macros 2x2 Grid
                VStack(spacing: 3) {
                    HStack(spacing: 0) {
                        Text("Protein ")
                            .foregroundColor(.secondary)
                        Text("\(Int(entry.protein))g")
                            .bold()
                        Spacer()
                        Text("Carbs ")
                            .foregroundColor(.secondary)
                        Text("\(Int(entry.carbs))g")
                            .bold()
                    }
                    HStack(spacing: 0) {
                        Text("Fat ")
                            .foregroundColor(.secondary)
                        Text("\(Int(entry.fat))g")
                            .bold()
                        Spacer()
                        Text("Fiber ")
                            .foregroundColor(.secondary)
                        Text("\(Int(entry.fiber))g")
                            .bold()
                    }
                }
                .font(.system(size: 10, design: .rounded))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {}
            .widgetURL(URL(string: "logcal://dashboard"))
            
        default:
            VStack(spacing: 7) {
                WidgetMacroRow(label: "Protein", value: entry.protein, goal: entry.proteinGoal, color: WidgetTheme.proteinGreen)
                WidgetMacroRow(label: "Carbs", value: entry.carbs, goal: entry.carbsGoal, color: WidgetTheme.carbsBlue)
                WidgetMacroRow(label: "Fat", value: entry.fat, goal: entry.fatGoal, color: WidgetTheme.fatOrange)
                WidgetMacroRow(label: "Fiber", value: entry.fiber, goal: entry.fiberGoal, color: WidgetTheme.fiberPurple)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(WidgetTheme.darkBackground, for: .widget)
            .widgetURL(URL(string: "logcal://dashboard"))
        }
    }
}

// MARK: - 3. Small Widget: Calories and Macros (Daily Summary)

struct DailySummaryWidgetView: View {
    let entry: SimpleEntry
    
    var isOverGoal: Bool {
        entry.dailyGoal > 0 && entry.calories > entry.dailyGoal
    }
    
    var remaining: Int {
        Int(max(entry.dailyGoal - entry.calories, 0))
    }
    
    var overdue: Int {
        Int(max(entry.calories - entry.dailyGoal, 0))
    }
    
    var calorieRingColor: Color {
        isOverGoal ? WidgetTheme.calorieExceededOrange : WidgetTheme.calorieGreen
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Upper Calorie Section (58% height)
            VStack(spacing: 4) {
                Spacer(minLength: 2)
                WidgetProgressRing(
                    consumed: entry.calories,
                    goal: entry.dailyGoal,
                    size: 58,
                    strokeWidth: 6,
                    color: calorieRingColor
                )
                .overlay(
                    VStack(spacing: -2) {
                        Text("\(Int(entry.calories))")
                            .font(.system(size: 14, weight: .bold).monospacedDigit())
                            .foregroundColor(WidgetTheme.primaryText)
                        Text("cal")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(WidgetTheme.mutedText)
                    }
                )
                
                if entry.dailyGoal > 0 {
                    if isOverGoal {
                        HStack(spacing: 2) {
                            Text("\(overdue)")
                                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                                .foregroundColor(WidgetTheme.calorieExceededOrange)
                            Text("overdue")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(WidgetTheme.calorieExceededOrange)
                        }
                    } else {
                        HStack(spacing: 2) {
                            Text("\(remaining)")
                                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                                .foregroundColor(WidgetTheme.calorieGreen)
                            Text("left")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(WidgetTheme.mutedText)
                        }
                    }
                } else {
                    Text("No goal")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(WidgetTheme.quietText)
                }
            }
            .frame(maxHeight: .infinity)
            
            Spacer(minLength: 6)
            
            // Lower Macro Section (42% height)
            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    WidgetMacroCell(label: "Protein", value: entry.protein, goal: entry.proteinGoal, color: WidgetTheme.proteinGreen)
                    WidgetMacroCell(label: "Carbs", value: entry.carbs, goal: entry.carbsGoal, color: WidgetTheme.carbsBlue)
                }
                HStack(spacing: 5) {
                    WidgetMacroCell(label: "Fat", value: entry.fat, goal: entry.fatGoal, color: WidgetTheme.fatOrange)
                    WidgetMacroCell(label: "Fiber", value: entry.fiber, goal: entry.fiberGoal, color: WidgetTheme.fiberPurple)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(WidgetTheme.darkBackground, for: .widget)
        .widgetURL(URL(string: "logcal://dashboard"))
    }
}

// MARK: - 4. Small Widget: Quick Log

struct QuickLogWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Large Voice Area at the top
            Button(intent: LogShortcutIntent(action: "voice")) {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            
            // Bottom Shortcuts (Camera, Gallery, Keyboard)
            HStack(spacing: 8) {
                Button(intent: LogShortcutIntent(action: "camera")) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(WidgetTheme.darkElevatedBackground)
                            .frame(height: 40)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(WidgetTheme.proteinGreen)
                    }
                }
                .buttonStyle(.plain)
                
                Button(intent: LogShortcutIntent(action: "gallery")) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(WidgetTheme.darkElevatedBackground)
                            .frame(height: 40)
                        
                        Image(systemName: "photo.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(WidgetTheme.carbsBlue)
                    }
                }
                .buttonStyle(.plain)
                
                Button(intent: LogShortcutIntent(action: "text")) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(WidgetTheme.darkElevatedBackground)
                            .frame(height: 40)
                        
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(WidgetTheme.carbsBlue)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(WidgetTheme.darkBackground, for: .widget)
    }
}

// MARK: - 5. Small Widget: Calories and Log

struct CaloriesAndLogWidgetView: View {
    let entry: SimpleEntry
    
    var isOverGoal: Bool {
        entry.dailyGoal > 0 && entry.calories > entry.dailyGoal
    }
    
    var calorieRingColor: Color {
        isOverGoal ? WidgetTheme.calorieExceededOrange : WidgetTheme.calorieGreen
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 4)
            
            // Calorie Ring Section
            WidgetProgressRing(
                consumed: entry.calories,
                goal: entry.dailyGoal,
                size: 82,
                strokeWidth: 8,
                color: calorieRingColor
            )
            .overlay(
                VStack(spacing: -1) {
                    Text("\(Int(entry.calories))")
                        .font(.system(size: 18, weight: .bold).monospacedDigit())
                        .foregroundColor(WidgetTheme.primaryText)
                    Text("cal")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(WidgetTheme.mutedText)
                    if entry.dailyGoal > 0 {
                        Text("of \(Int(entry.dailyGoal)) cal")
                            .font(.system(size: 8, weight: .regular))
                            .foregroundColor(WidgetTheme.quietText)
                    } else {
                        Text("No goal")
                            .font(.system(size: 8, weight: .regular))
                            .foregroundColor(WidgetTheme.quietText)
                    }
                }
            )
            
            Spacer(minLength: 8)
            
            // Bottom Shortcut Row
            HStack(spacing: 8) {
                // Voice (Orange)
                Button(intent: LogShortcutIntent(action: "voice")) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange)
                            .frame(height: 38)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                // Keyboard (Dark Neutral, White Icon)
                Button(intent: LogShortcutIntent(action: "text")) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(WidgetTheme.darkElevatedBackground)
                            .frame(height: 38)
                        
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                // Camera (Dark Neutral, White Icon)
                Button(intent: LogShortcutIntent(action: "camera")) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(WidgetTheme.darkElevatedBackground)
                            .frame(height: 38)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(WidgetTheme.darkBackground, for: .widget)
    }
}

// MARK: - 6. Medium Widget: Daily Dashboard (Calories, Macros, and Log)

struct DailyDashboardWidgetView: View {
    let entry: SimpleEntry
    
    var isOverGoal: Bool {
        entry.dailyGoal > 0 && entry.calories > entry.dailyGoal
    }
    
    var remaining: Int {
        Int(max(entry.dailyGoal - entry.calories, 0))
    }
    
    var overdue: Int {
        Int(max(entry.calories - entry.dailyGoal, 0))
    }
    
    var calorieRingColor: Color {
        isOverGoal ? WidgetTheme.calorieExceededOrange : WidgetTheme.calorieGreen
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Upper Content Section (72% height)
            HStack(spacing: 0) {
                // Left Column: Calories (43% width)
                Link(destination: URL(string: "logcal://dashboard")!) {
                    VStack(spacing: 4) {
                        WidgetProgressRing(
                            consumed: entry.calories,
                            goal: entry.dailyGoal,
                            size: 76,
                            strokeWidth: 8,
                            color: calorieRingColor
                        )
                        .overlay(
                            VStack(spacing: -1) {
                                Text("\(Int(entry.calories))")
                                    .font(.system(size: 16, weight: .bold).monospacedDigit())
                                    .foregroundColor(WidgetTheme.primaryText)
                                Text("cal")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(WidgetTheme.mutedText)
                                if entry.dailyGoal > 0 {
                                    Text("of \(Int(entry.dailyGoal)) cal")
                                        .font(.system(size: 8, weight: .regular))
                                        .foregroundColor(WidgetTheme.quietText)
                                } else {
                                    Text("No goal")
                                        .font(.system(size: 8, weight: .regular))
                                        .foregroundColor(WidgetTheme.quietText)
                                }
                            }
                        )
                        
                        if entry.dailyGoal > 0 {
                            if isOverGoal {
                                HStack(spacing: 3) {
                                    Text("\(overdue)")
                                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                                        .foregroundColor(WidgetTheme.calorieExceededOrange)
                                    Text("cal overdue")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(WidgetTheme.calorieExceededOrange)
                                }
                            } else {
                                HStack(spacing: 3) {
                                    Text("\(remaining)")
                                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                                        .foregroundColor(WidgetTheme.calorieGreen)
                                    Text("cal left")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(WidgetTheme.mutedText)
                                }
                            }
                        } else {
                            Text("No goal set")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(WidgetTheme.quietText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Subtle Vertical Divider
                Rectangle()
                    .fill(WidgetTheme.darkNeutralTrack)
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                // Right Column: Macros (57% width)
                Link(destination: URL(string: "logcal://dashboard")!) {
                    VStack(spacing: 6) {
                        WidgetMacroRow(label: "Protein", value: entry.protein, goal: entry.proteinGoal, color: WidgetTheme.proteinGreen)
                        WidgetMacroRow(label: "Carbs", value: entry.carbs, goal: entry.carbsGoal, color: WidgetTheme.carbsBlue)
                        WidgetMacroRow(label: "Fat", value: entry.fat, goal: entry.fatGoal, color: WidgetTheme.fatOrange)
                        WidgetMacroRow(label: "Fiber", value: entry.fiber, goal: entry.fiberGoal, color: WidgetTheme.fiberPurple)
                    }
                    .padding(.leading, 14)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxHeight: .infinity)
            
            // Subtle Horizontal Divider
            Rectangle()
                .fill(WidgetTheme.darkNeutralTrack)
                .frame(height: 1)
            
            // Bottom Logging Row (28% height)
            HStack(spacing: 8) {
                // Camera
                Link(destination: URL(string: "logcal://log?action=camera")!) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(WidgetTheme.darkElevatedBackground)
                            .frame(width: 38, height: 34)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(WidgetTheme.proteinGreen)
                    }
                }
                
                // Gallery
                Link(destination: URL(string: "logcal://log?action=gallery")!) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(WidgetTheme.darkElevatedBackground)
                            .frame(width: 38, height: 34)
                        
                        Image(systemName: "photo.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(WidgetTheme.carbsBlue)
                    }
                }
                
                // Manual text entry visual shortcut (widest)
                Link(destination: URL(string: "logcal://log?action=text")!) {
                    HStack {
                        Text("Type a meal...")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(WidgetTheme.mutedText)
                            .padding(.leading, 12)
                        Spacer()
                    }
                    .frame(height: 34)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(WidgetTheme.darkElevatedBackground)
                    )
                }
                
                // Voice
                Link(destination: URL(string: "logcal://log?action=voice")!) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange)
                            .frame(width: 38, height: 34)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(WidgetTheme.darkBackground, for: .widget)
    }
}

struct LockScreenCameraWidgetView: View {
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "camera.fill")
                .font(.system(size: 20))
            Text("Log Meal")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
        .widgetURL(URL(string: "logcal://log?action=camera"))
    }
}

struct LockScreenMicWidgetView: View {
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "mic.fill")
                .font(.system(size: 20))
            Text("Log Meal")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
        .widgetURL(URL(string: "logcal://log?action=voice"))
    }
}

struct LockScreenCalorieAndLogWidgetView: View {
    let entry: SimpleEntry
    
    var isOverGoal: Bool {
        entry.dailyGoal > 0 && entry.calories > entry.dailyGoal
    }
    
    var remaining: Int {
        Int(max(entry.dailyGoal - entry.calories, 0))
    }
    
    var overdue: Int {
        Int(max(entry.calories - entry.dailyGoal, 0))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Top: Calorie Progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Calories")
                        .foregroundColor(.secondary)
                    Spacer()
                    if entry.dailyGoal > 0 {
                        if isOverGoal {
                            Text("\(overdue) cal overdue")
                                .bold()
                        } else {
                            Text("\(remaining) cal left")
                                .bold()
                        }
                    } else {
                        Text("\(Int(entry.calories)) cal")
                            .bold()
                    }
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                
                if entry.dailyGoal > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.15))
                            if entry.calories > 0 {
                                let progress = min(max(entry.calories / entry.dailyGoal, 0.0), 1.0)
                                Capsule()
                                    .fill(Color.primary)
                                    .frame(width: geo.size.width * CGFloat(progress))
                            }
                        }
                    }
                    .frame(height: 12)
                }
            }
            
            Spacer(minLength: 0)
            
            // Bottom: Tap to log text
            HStack {
                Text("Tap to log meal")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {}
        .widgetURL(URL(string: "logcal://log"))
    }
}

// MARK: - Previews

struct LogCalWidgetViews_Previews: PreviewProvider {
    static var previews: some View {
        let normal = SimpleEntry(
            date: Date(),
            calories: 1420,
            dailyGoal: 2000,
            protein: 82,
            carbs: 146,
            fat: 41,
            fiber: 18,
            proteinGoal: 120,
            carbsGoal: 220,
            fatGoal: 65,
            fiberGoal: 30
        )
        
        let zero = SimpleEntry(
            date: Date(),
            calories: 0,
            dailyGoal: 2000,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            proteinGoal: 120,
            carbsGoal: 220,
            fatGoal: 65,
            fiberGoal: 30
        )
        
        let exceeded = SimpleEntry(
            date: Date(),
            calories: 2200,
            dailyGoal: 2000,
            protein: 130,
            carbs: 240,
            fat: 75,
            fiber: 35,
            proteinGoal: 120,
            carbsGoal: 220,
            fatGoal: 65,
            fiberGoal: 30
        )
        
        let missingGoals = SimpleEntry(
            date: Date(),
            calories: 1420,
            dailyGoal: 0,
            protein: 82,
            carbs: 146,
            fat: 41,
            fiber: 18,
            proteinGoal: 0,
            carbsGoal: 0,
            fatGoal: 0,
            fiberGoal: 0
        )

        Group {
            // Previews for Calories Widget
            CaloriesWidgetView(entry: normal)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Calories - Normal")
            
            CaloriesWidgetView(entry: missingGoals)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Calories - No Goals")

            // Previews for Macros Widget
            MacrosWidgetView(entry: normal)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Macros - Normal")
            
            MacrosWidgetView(entry: exceeded)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Macros - Exceeded")

            // Previews for Daily Summary
            DailySummaryWidgetView(entry: normal)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Summary - Normal")

            DailySummaryWidgetView(entry: missingGoals)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Summary - No Goals")

            // Previews for Quick Log
            QuickLogWidgetView(entry: zero)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Quick Log")

            // Previews for Calories and Log
            CaloriesAndLogWidgetView(entry: normal)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Cal & Log - Normal")

            // Previews for Daily Dashboard (Medium)
            DailyDashboardWidgetView(entry: normal)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Dashboard - Normal")
            
            DailyDashboardWidgetView(entry: zero)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Dashboard - Zero")

            DailyDashboardWidgetView(entry: missingGoals)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Dashboard - No Goals")
        }
    }
}
