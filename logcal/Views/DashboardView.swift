//
//  DashboardView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \MealEntry.timestamp, order: .reverse) private var meals: [MealEntry]
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @AppStorage("dailyGoal") private var dailyGoal: Double = 2000
    @AppStorage("proteinGoal") private var proteinGoal: Double = 150
    @AppStorage("carbsGoal") private var carbsGoal: Double = 200
    @AppStorage("fatGoal") private var fatGoal: Double = 65
    
    init() {
        // #region agent log
        DebugLogger.log(location: "DashboardView.swift:12", message: "DashboardView init", data: [:], hypothesisId: "B")
        // #endregion
    }
    
    // Today's calories
    private var todayCalories: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return meals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .reduce(0) { $0 + $1.totalCalories }
    }
    
    /// Uncapped ratio for today's calories card (ring caps at full circle; center label can exceed 100%).
    private var calorieProgressRatio: Double {
        guard dailyGoal > 0 else { return 0 }
        return todayCalories / dailyGoal
    }
    
    // Today's macros
    private var todayProtein: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        let proteinValues = todayMeals.compactMap { $0.protein }
        let result = proteinValues.reduce(0, +)
        // #region agent log
        if let debugLogData = try? JSONSerialization.data(withJSONObject: ["location": "DashboardView.swift:46", "message": "todayProtein calculation", "data": ["todayMealsCount": todayMeals.count, "proteinValuesCount": proteinValues.count, "proteinValues": proteinValues, "result": result], "timestamp": Date().timeIntervalSince1970 * 1000, "sessionId": "debug-session", "runId": "run1", "hypothesisId": "D"]), let logString = String(data: debugLogData, encoding: .utf8) {
            try? (logString + "\n").write(toFile: "/Users/ajohri/Documents/Antriksh Personal/LogCal/logcal/.cursor/debug.log", atomically: false, encoding: .utf8)
        }
        // #endregion
        return result
    }
    
    private var todayCarbs: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return meals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .compactMap { $0.carbs }
            .reduce(0, +)
    }
    
    private var todayFat: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return meals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .compactMap { $0.fat }
            .reduce(0, +)
    }
    
    // Weekly data (last 7 days)
    private var weeklyData: [(day: String, calories: Double, isToday: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E" // Single letter day (M, T, W, etc.)
        
        var weekData: [(day: String, calories: Double, isToday: Bool)] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayLabel = dateFormatter.string(from: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)
            
            let dayCalories = meals
                .filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
                .reduce(0) { $0 + $1.totalCalories }
            
            weekData.append((day: dayLabel, calories: dayCalories, isToday: isToday))
        }
        
        // Reverse to show oldest to newest (left to right)
        return weekData.reversed()
    }
    
    // Weekly average
    private var weeklyAverage: Double {
        let total = weeklyData.reduce(0) { $0 + $1.calories }
        return total / 7.0
    }
    
    // Streak calculation
    private var streakDays: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all unique dates that have meals
        let mealDates = Set(meals.map { calendar.startOfDay(for: $0.timestamp) })
        
        // If no meals, streak is 0
        guard let mostRecentMealDate = mealDates.max() else { return 0 }
        
        // If most recent meal is today or yesterday, count from there
        // Otherwise, if it's earlier, streak is broken
        let daysSinceMostRecent = calendar.dateComponents([.day], from: mostRecentMealDate, to: today).day ?? 0
        
        // If most recent meal was more than 1 day ago (excluding today), streak is broken
        if daysSinceMostRecent > 1 {
            return 0
        }
        
        // Count consecutive days backwards from most recent meal date
        var streak = 0
        var currentDate = mostRecentMealDate
        
        while mealDates.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }
        
        return streak
    }

    private var todayDateText: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    private var dailyStatusText: String {
        guard dailyGoal > 0 else { return "Set a daily goal to track progress" }
        if todayCalories > dailyGoal {
            return "\(Int(todayCalories - dailyGoal)) cal over target"
        }
        return "\(Int(dailyGoal - todayCalories)) cal remaining today"
    }

    private var dailyStatusColor: Color {
        todayCalories > dailyGoal ? Theme.warningAmber : Theme.primaryGreen
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Spacing.extraLarge) {
                    HStack(alignment: .center, spacing: Constants.Spacing.regular) {
                        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                            Text("Today")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))

                            Text(todayDateText)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        }

                        Spacer()

                        HStack(spacing: Constants.Spacing.small) {
                            Circle()
                                .fill(dailyStatusColor)
                                .frame(width: 8, height: 8)

                            Text(dailyStatusText)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(dailyStatusColor)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                        }
                        .padding(.horizontal, Constants.Spacing.regular)
                        .padding(.vertical, Constants.Spacing.medium)
                        .background(Theme.softAccentBackground(colorScheme: colorScheme))
                        .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.top, Constants.Spacing.large)
                    
                    TodaysCaloriesCard(
                        calories: todayCalories,
                        goal: dailyGoal,
                        progress: calorieProgressRatio
                    )
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    
                    // Today's Macros Card
                    TodaysMacrosCard(
                        protein: todayProtein,
                        carbs: todayCarbs,
                        fat: todayFat,
                        proteinGoal: proteinGoal,
                        carbsGoal: carbsGoal,
                        fatGoal: fatGoal
                    )
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    
                    // This Week Card
                    ThisWeekCard(
                        weeklyData: weeklyData,
                        weeklyAverage: weeklyAverage,
                        dailyGoal: dailyGoal
                    )
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    
                    // Daily Goal and Streak Cards
                    HStack(spacing: Constants.Spacing.regular) {
                        DailyGoalCard(goal: dailyGoal)
                        StreakCard(streak: streakDays)
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                }
                .padding(.bottom, Constants.Spacing.extraLarge)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Theme.backgroundColor(colorScheme: colorScheme))
            .onAppear {
                // #region agent log
                DebugLogger.log(location: "DashboardView.swift:onAppear", message: "DashboardView appeared", data: ["mealCount": meals.count], hypothesisId: "B")
                // #endregion
            }
            .onChange(of: meals.count) { oldValue, newValue in
                // #region agent log
                DebugLogger.log(location: "DashboardView.swift:onChange", message: "Meals count changed", data: ["oldCount": oldValue, "newCount": newValue], hypothesisId: "B")
                // #endregion
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [MealEntry.self, SavedMeal.self])
}
