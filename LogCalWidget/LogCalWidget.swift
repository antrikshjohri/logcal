//
//  LogCalWidget.swift
//  LogCalWidget
//
//  Created by Antriksh Johri on 19/06/26.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct SimpleEntry: TimelineEntry {
    let date: Date
    let calories: Double
    let dailyGoal: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let proteinGoal: Double
    let carbsGoal: Double
    let fatGoal: Double
    let fiberGoal: Double
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            calories: 1250,
            dailyGoal: 2000,
            protein: 85,
            carbs: 140,
            fat: 45,
            fiber: 18,
            proteinGoal: 150,
            carbsGoal: 200,
            fatGoal: 65,
            fiberGoal: 28
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let now = Date()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        
        let appGroup = "group.com.serene.logcal"
        let fileManager = FileManager.default
        
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        var fiber: Double = 0
        
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            let storeURL = containerURL.appendingPathComponent("default.store")
            let configuration = ModelConfiguration(url: storeURL)
            if let container = try? ModelContainer(for: Schema([MealEntry.self, SavedMeal.self]), configurations: [configuration]) {
                let context = ModelContext(container)
                
                // Fetch today's entries (active meals)
                let descriptor = FetchDescriptor<MealEntry>(
                    predicate: #Predicate<MealEntry> { !$0.deleted }
                )
                if let meals = try? context.fetch(descriptor) {
                    let todayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
                    calories = todayMeals.reduce(0) { $0 + $1.totalCalories }
                    protein = todayMeals.compactMap { $0.protein }.reduce(0, +)
                    carbs = todayMeals.compactMap { $0.carbs }.reduce(0, +)
                    fat = todayMeals.compactMap { $0.fat }.reduce(0, +)
                    fiber = todayMeals.compactMap { $0.fiber }.reduce(0, +)
                }
            }
        }
        
        // Read goals from shared UserDefaults
        let defaults = UserDefaults(suiteName: appGroup)
        let dailyGoal = defaults?.double(forKey: "dailyGoal") ?? 2000
        let proteinGoal = defaults?.double(forKey: "proteinGoal") ?? 150
        let carbsGoal = defaults?.double(forKey: "carbsGoal") ?? 200
        let fatGoal = defaults?.double(forKey: "fatGoal") ?? 65
        let fiberGoal = (dailyGoal / 1000.0) * 14.0
        
        let entry = SimpleEntry(
            date: now,
            calories: calories,
            dailyGoal: dailyGoal,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            proteinGoal: proteinGoal,
            carbsGoal: carbsGoal,
            fatGoal: fatGoal,
            fiberGoal: fiberGoal
        )
        
        // Update widget timeline every 15 minutes
        let nextUpdate = calendar.date(byAdding: .minute, value: 15, to: now) ?? now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
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
        var urlString = "logcal://log"
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
        
        // Open URL dynamically to avoid extension target compilation warnings/errors
        if let applicationClass = NSClassFromString("UIApplication") as? NSObject.Type {
            let sharedSelector = Selector(("sharedApplication"))
            if applicationClass.responds(to: sharedSelector) {
                let sharedApplication = applicationClass.perform(sharedSelector).takeUnretainedValue()
                let openURLSelector = Selector(("openURL:"))
                if sharedApplication.responds(to: openURLSelector) {
                    _ = sharedApplication.perform(openURLSelector, with: destinationURL)
                }
            }
        }
        
        return .result()
    }
}

struct CaloriesWidget: Widget {
    let kind: String = "CaloriesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CaloriesWidgetView(entry: entry)
        }
        .configurationDisplayName("Calories")
        .description("See today’s calorie progress and remaining calories.")
        .supportedFamilies([.systemSmall])
    }
}

struct MacrosWidget: Widget {
    let kind: String = "MacrosWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MacrosWidgetView(entry: entry)
        }
        .configurationDisplayName("Macros")
        .description("Track protein, carbs, fat and fibre.")
        .supportedFamilies([.systemSmall])
    }
}

struct DailySummaryWidget: Widget {
    let kind: String = "DailySummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DailySummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Summary")
        .description("See calories and key nutrition progress together.")
        .supportedFamilies([.systemSmall])
    }
}

struct QuickLogWidget: Widget {
    let kind: String = "QuickLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuickLogWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Log")
        .description("Start voice, camera, gallery or manual logging.")
        .supportedFamilies([.systemSmall])
    }
}

struct CaloriesAndLogWidget: Widget {
    let kind: String = "CaloriesAndLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CaloriesAndLogWidgetView(entry: entry)
        }
        .configurationDisplayName("Calories & Log")
        .description("Check calories and quickly log your next meal.")
        .supportedFamilies([.systemSmall])
    }
}

struct DailyDashboardWidget: Widget {
    let kind: String = "DailyDashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DailyDashboardWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Dashboard")
        .description("View calories, nutrition progress and logging shortcuts.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct LogCalWidgetBundle: WidgetBundle {
    var body: some Widget {
        CaloriesWidget()
        MacrosWidget()
        DailySummaryWidget()
        QuickLogWidget()
        CaloriesAndLogWidget()
        DailyDashboardWidget()
    }
}

