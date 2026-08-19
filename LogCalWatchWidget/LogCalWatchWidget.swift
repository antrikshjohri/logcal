//
//  LogCalWatchWidget.swift
//  LogCalWatchWidget
//
//  Created by Antriksh Johri on 19/08/26.
//

import WidgetKit
import SwiftUI

// MARK: - 1. Daily Stats Complication (Rectangular, Circular, Inline, Corner)
struct LogCalWatchStatsWidget: Widget {
    let kind: String = "LogCalWatchStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LogCalWatchTimelineProvider()) { entry in
            LogCalWatchComplicationEntryView(entry: entry)
                .widgetContainerBackground()
        }
        .configurationDisplayName("Daily Nutrition")
        .description("Track your daily calories, progress ring, and macros on your watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

struct LogCalWatchComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LogCalWatchEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            WatchAccessoryRectangularView(entry: entry)
        case .accessoryCircular:
            WatchAccessoryCircularView(entry: entry)
        case .accessoryInline:
            WatchAccessoryInlineView(entry: entry)
        case .accessoryCorner:
            WatchAccessoryCornerView(entry: entry)
        default:
            WatchAccessoryCircularView(entry: entry)
        }
    }
}

// MARK: - 2. Quick Log Action Shortcut Complication
struct LogCalWatchQuickLogWidget: Widget {
    let kind: String = "LogCalWatchQuickLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LogCalWatchTimelineProvider()) { _ in
            ZStack {
                Circle()
                    .fill(Color(red: 0.18, green: 0.80, blue: 0.44).opacity(0.2))
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.18, green: 0.80, blue: 0.44))
            }
            .widgetURL(URL(string: "logcal://voice-log"))
            .widgetContainerBackground()
        }
        .configurationDisplayName("Quick Log Meal")
        .description("1-tap shortcut to dictate and log a meal directly from your watch face.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

// MARK: - Helper Extension for Background Compatibility
extension View {
    @ViewBuilder
    func widgetContainerBackground() -> some View {
        if #available(watchOS 10.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self
        }
    }
}

// MARK: - Complication Bundle
@main
struct LogCalWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        LogCalWatchStatsWidget()
        LogCalWatchQuickLogWidget()
    }
}
