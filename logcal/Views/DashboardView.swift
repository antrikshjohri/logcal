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
    
    // Remaining calories
    private var remainingCalories: Double {
        max(dailyGoal - todayCalories, 0)
    }
    
    // Progress percentage
    private var progressPercentage: Double {
        min(todayCalories / dailyGoal, 1.0)
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // Header
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Dashboard")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Track your daily progress")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Constants.Colors.secondaryGray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.top, Constants.Spacing.regular)
                    
                    // Today's Calories Card
                    TodaysCaloriesCard(
                        calories: todayCalories,
                        goal: dailyGoal,
                        remaining: remainingCalories,
                        progress: progressPercentage
                    )
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    
                    // This Week Card
                    ThisWeekCard(
                        weeklyData: weeklyData,
                        weeklyAverage: weeklyAverage
                    )
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    
                    // Daily Goal and Streak Cards
                    HStack(spacing: Constants.Spacing.regular) {
                        DailyGoalCard(goal: dailyGoal)
                        StreakCard(streak: streakDays)
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                }
                .padding(.vertical, Constants.Spacing.large)
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

// MARK: - Theme Colors
struct Theme {
    static func backgroundColor(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black : Color(.systemGroupedBackground)
    }
    
    static func cardBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.15) // Dark gray for dark mode
            : Color.white // White for light mode
    }
    
    static func cardBorder(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1) // Subtle white border in dark mode
            : Color.gray.opacity(0.2) // Subtle gray border in light mode
    }
    
    static let accentBlue = Constants.Colors.primaryBlue
    static let secondaryText = Constants.Colors.secondaryGray
}

#Preview {
    DashboardView()
        .modelContainer(for: MealEntry.self)
}
