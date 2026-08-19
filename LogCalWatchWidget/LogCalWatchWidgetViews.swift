//
//  LogCalWatchWidgetViews.swift
//  LogCalWatchWidget
//
//  Created by Antriksh Johri on 19/08/26.
//

import SwiftUI
import WidgetKit

struct LogCalWatchEntry: TimelineEntry {
    let date: Date
    let todayCalories: Double
    let dailyGoal: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
}

struct LogCalWatchTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> LogCalWatchEntry {
        LogCalWatchEntry(
            date: Date(),
            todayCalories: 1450,
            dailyGoal: 2000,
            protein: 110,
            carbs: 165,
            fat: 45,
            fiber: 25
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LogCalWatchEntry) -> Void) {
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LogCalWatchEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> LogCalWatchEntry {
        let defaults = UserDefaults(suiteName: "group.com.serene.logcal") ?? .standard
        let cal = defaults.double(forKey: "todayCalories")
        let goalVal = defaults.double(forKey: "dailyCalorieGoal")
        let goal = goalVal > 0 ? goalVal : 2000
        let p = defaults.double(forKey: "todayProtein")
        let c = defaults.double(forKey: "todayCarbs")
        let f = defaults.double(forKey: "todayFat")
        let fib = defaults.double(forKey: "todayFiber")
        return LogCalWatchEntry(
            date: Date(),
            todayCalories: cal,
            dailyGoal: goal,
            protein: p,
            carbs: c,
            fat: f,
            fiber: fib
        )
    }
}

// MARK: - 1. Rectangular Complication (Calories + Progress Bar + Macros)
struct WatchAccessoryRectangularView: View {
    let entry: LogCalWatchEntry
    
    private var progress: Double {
        entry.dailyGoal > 0 ? min(max(entry.todayCalories / entry.dailyGoal, 0.0), 1.0) : 0.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Header Row
            HStack {
                Text("Calories")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.18, green: 0.80, blue: 0.44))
                Spacer()
                Text("\(Int(entry.todayCalories)) / \(Int(entry.dailyGoal))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                    if progress > 0 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.18, green: 0.80, blue: 0.44), Color(red: 0.12, green: 0.55, blue: 0.35)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * CGFloat(progress), 4))
                    }
                }
            }
            .frame(height: 4)
            
            // 3-4 Macros Row
            HStack(spacing: 0) {
                Text("P: \(Int(entry.protein))g")
                    .foregroundColor(Color(red: 0.95, green: 0.38, blue: 0.38))
                Spacer()
                Text("C: \(Int(entry.carbs))g")
                    .foregroundColor(Color(red: 0.95, green: 0.70, blue: 0.25))
                Spacer()
                Text("F: \(Int(entry.fat))g")
                    .foregroundColor(Color(red: 0.30, green: 0.75, blue: 0.95))
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .widgetURL(URL(string: "logcal://home"))
    }
}

// MARK: - 2. Circular Dial Complication
struct WatchAccessoryCircularView: View {
    let entry: LogCalWatchEntry
    
    private var progress: Double {
        entry.dailyGoal > 0 ? min(max(entry.todayCalories / entry.dailyGoal, 0.0), 1.0) : 0.0
    }
    
    var body: some View {
        Gauge(value: progress, in: 0...1) {
            Image(systemName: "flame.fill")
                .foregroundColor(Color(red: 0.18, green: 0.80, blue: 0.44))
        } currentValueLabel: {
            Text("\(Int(entry.todayCalories))")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(Color(red: 0.18, green: 0.80, blue: 0.44))
        .widgetURL(URL(string: "logcal://home"))
    }
}

// MARK: - 3. Inline Complication
struct WatchAccessoryInlineView: View {
    let entry: LogCalWatchEntry
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
            Text("\(Int(entry.todayCalories)) / \(Int(entry.dailyGoal)) cal")
        }
    }
}

// MARK: - 4. Corner Complication
struct WatchAccessoryCornerView: View {
    let entry: LogCalWatchEntry
    
    private var progress: Double {
        entry.dailyGoal > 0 ? min(max(entry.todayCalories / entry.dailyGoal, 0.0), 1.0) : 0.0
    }
    
    var body: some View {
        Text("\(Int(entry.todayCalories))")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .widgetCurvesContent()
            .widgetLabel {
                ProgressView(value: progress, total: 1.0)
                    .tint(Color(red: 0.18, green: 0.80, blue: 0.44))
            }
            .widgetURL(URL(string: "logcal://home"))
    }
}
