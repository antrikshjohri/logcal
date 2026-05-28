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
    @EnvironmentObject var cloudSyncService: CloudSyncService
    @Binding var selectedTab: Int
    @AppStorage("dailyGoal") private var dailyGoal: Double = 2000
    @AppStorage("proteinGoal") private var proteinGoal: Double = 150
    @AppStorage("carbsGoal") private var carbsGoal: Double = 200
    @AppStorage("fatGoal") private var fatGoal: Double = 65
    @State private var showEditGoalSheet = false
    @AppStorage("navigateToDate") private var navigateToDateTimestamp: Double = 0
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
        // #region agent log
        DebugLogger.log(location: "DashboardView.swift:12", message: "DashboardView init", data: [:], hypothesisId: "B")
        // #endregion
    }
    
    // Selected day's calories
    private var todayCalories: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        return meals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .reduce(0) { $0 + $1.totalCalories }
    }
    
    private var todayMeals: [MealEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        return meals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    /// Uncapped ratio for selected day's calories card (ring caps at full circle; center label can exceed 100%).
    private var calorieProgressRatio: Double {
        guard dailyGoal > 0 else { return 0 }
        return todayCalories / dailyGoal
    }
    
    // Selected day's macros
    private var todayProtein: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
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
        let today = calendar.startOfDay(for: selectedDate)
        return meals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .compactMap { $0.carbs }
            .reduce(0, +)
    }
    
    private var todayFat: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        return meals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .compactMap { $0.fat }
            .reduce(0, +)
    }
    
    // Weekly data centered around selectedDate
    private var weeklyData: [(day: String, calories: Double, isToday: Bool)] {
        let calendar = Calendar.current
        let anchorDate = calendar.startOfDay(for: selectedDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E" // Single letter day (M, T, W, etc.)
        
        var weekData: [(day: String, calories: Double, isToday: Bool)] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: anchorDate) else { continue }
            let dayLabel = dateFormatter.string(from: date)
            let isSelected = calendar.isDate(date, inSameDayAs: anchorDate)
            
            let dayCalories = meals
                .filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
                .reduce(0) { $0 + $1.totalCalories }
            
            weekData.append((day: dayLabel, calories: dayCalories, isToday: isSelected))
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

    private var displayDateTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Monday, Tuesday, etc.
            return formatter.string(from: selectedDate)
        }
    }

    private var formattedDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    private func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private var isOverGoal: Bool { todayCalories > dailyGoal }
    private var remainingUnderGoal: Double { max(0, dailyGoal - todayCalories) }
    private var amountOverGoal: Double { max(0, todayCalories - dailyGoal) }

    private var dailyStatusColor: Color {
        isOverGoal ? Theme.warningAmber : Theme.primaryGreen
    }

    private var statusCardTitle: String {
        if dailyGoal <= 0 {
            return "Set a daily goal"
        }
        if isOverGoal {
            return "Over your daily target"
        }
        return "On track for your goal"
    }
    
    private var statusCardSubtitle: String {
        if dailyGoal <= 0 {
            return "Track your progress by setting a goal."
        }
        if isOverGoal {
            return "\(Int(amountOverGoal)) cal over target"
        }
        return "Great choices so far today!"
    }
    
    private var statusCardIcon: String {
        isOverGoal ? "exclamationmark.triangle.fill" : "checkmark"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Spacing.extraLarge) {
                    // Header Section
                    HStack(alignment: .center) {
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                changeDate(by: -1)
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.primaryGreen)
                                    .frame(width: 32, height: 32)
                                    .background(Theme.softAccentBackground(colorScheme: colorScheme))
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                showDatePicker = true
                            }) {
                                VStack(alignment: .center, spacing: 2) {
                                    Text(displayDateTitle)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                    
                                    Text(formattedDateText)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                }
                                .frame(width: 140)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .highPriorityGesture(
                                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                                    .onEnded { value in
                                        let threshold: CGFloat = 30
                                        if value.translation.width > threshold {
                                            changeDate(by: -1)
                                        } else if value.translation.width < -threshold {
                                            let isToday = Calendar.current.isDateInToday(selectedDate)
                                            if !isToday {
                                                changeDate(by: 1)
                                            }
                                        }
                                    }
                            )
                            
                            let isToday = Calendar.current.isDateInToday(selectedDate)
                            Button(action: {
                                changeDate(by: 1)
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(isToday ? Theme.mutedText(colorScheme: colorScheme).opacity(0.3) : Theme.primaryGreen)
                                    .frame(width: 32, height: 32)
                                    .background(isToday ? Color.clear : Theme.softAccentBackground(colorScheme: colorScheme))
                                    .clipShape(Circle())
                            }
                            .disabled(isToday)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.top, Constants.Spacing.large)
                    
                    // Status Card
                    HStack(spacing: Constants.Spacing.large) {
                        ZStack {
                            Circle()
                                .fill(dailyStatusColor)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: statusCardIcon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(statusCardTitle)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            
                            Text(statusCardSubtitle)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "leaf")
                            .font(.system(size: 28))
                            .foregroundColor(dailyStatusColor.opacity(0.25))
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                            .fill(dailyStatusColor.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                            .stroke(dailyStatusColor.opacity(0.18), lineWidth: 1)
                    )
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    
                    if horizontalSizeClass == .regular {
                        HStack(alignment: .top, spacing: Constants.Spacing.extraLarge) {
                            // Left Column
                            VStack(spacing: Constants.Spacing.extraLarge) {
                                TodaysCaloriesCard(
                                    calories: todayCalories,
                                    goal: dailyGoal,
                                    progress: calorieProgressRatio
                                )
                                
                                TodaysMacrosCard(
                                    protein: todayProtein,
                                    carbs: todayCarbs,
                                    fat: todayFat,
                                    proteinGoal: proteinGoal,
                                    carbsGoal: carbsGoal,
                                    fatGoal: fatGoal,
                                    onDetailsTapped: {
                                        navigateToDateTimestamp = selectedDate.timeIntervalSince1970
                                        selectedTab = 2
                                    }
                                )
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Right Column
                            VStack(spacing: Constants.Spacing.extraLarge) {
                                ThisWeekCard(
                                    weeklyData: weeklyData,
                                    weeklyAverage: weeklyAverage,
                                    dailyGoal: dailyGoal
                                )
                                
                                HStack(spacing: Constants.Spacing.regular) {
                                    Button(action: {
                                        showEditGoalSheet = true
                                    }) {
                                        DailyGoalCard(goal: dailyGoal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    StreakCard(streak: streakDays)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    } else {
                        // Calories Card
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
                            fatGoal: fatGoal,
                            onDetailsTapped: {
                                navigateToDateTimestamp = selectedDate.timeIntervalSince1970
                                selectedTab = 2
                            }
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
                            Button(action: {
                                showEditGoalSheet = true
                            }) {
                                DailyGoalCard(goal: dailyGoal)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            StreakCard(streak: streakDays)
                        }
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    }
                    
                    // Today's Meals Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Meals")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                            .padding(.top, Constants.Spacing.regular)
                        
                        if todayMeals.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                Text("No meals logged yet today")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(Constants.Sizes.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(todayMeals) { meal in
                                    MealRowView(meal: meal)
                                        .padding(.horizontal, Constants.Spacing.large)
                                    
                                    if meal.id != todayMeals.last?.id {
                                        Divider()
                                            .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                            .padding(.horizontal, Constants.Spacing.large)
                                    }
                                }
                            }
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(Constants.Sizes.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        }
                    }
                    .frame(maxWidth: horizontalSizeClass == .regular ? 950 : .infinity)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.bottom, Constants.Spacing.extraLarge)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Theme.backgroundColor(colorScheme: colorScheme))
            .sheet(isPresented: $showEditGoalSheet) {
                NavigationStack {
                    DailyGoalView()
                        .environmentObject(cloudSyncService)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                LogDatePickerSheet(selectedDate: $selectedDate, isPresented: $showDatePicker)
            }
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

private struct LogDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var dayBaselineForDismiss: Date?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundColor(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .tint(Theme.primaryGreen)
                        .padding(8)
                    }
                    .background(Theme.cardBackground(colorScheme: colorScheme))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                    )
                    .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.4), radius: 8, x: 0, y: 4)
                    .padding(16)
                    
                    Spacer()
                }
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryGreen)
                }
            }
            .onAppear {
                dayBaselineForDismiss = selectedDate
            }
            .onChange(of: selectedDate) { _, newValue in
                guard let baseline = dayBaselineForDismiss else { return }
                if !Calendar.current.isDate(newValue, equalTo: baseline, toGranularity: .day) {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    DashboardView(selectedTab: .constant(0))
        .modelContainer(for: [MealEntry.self, SavedMeal.self])
}
