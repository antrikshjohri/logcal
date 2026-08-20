//
//  DashboardView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(filter: #Predicate<MealEntry> { !$0.deleted }, sort: \MealEntry.timestamp, order: .reverse) private var meals: [MealEntry]
    @Query(sort: \SavedMeal.displayOrder, order: .forward) private var savedMeals: [SavedMeal]
    
    private var activeMeals: [MealEntry] {
        meals.filter { $0.modelContext != nil && !$0.isDeleted && !$0.deleted }
    }
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var cloudSyncService: CloudSyncService
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var toastManager: ToastManager
    @Binding var selectedTab: Int
    @AppStorage("dailyGoal") private var dailyGoal: Double = 2000
    @AppStorage("proteinGoal") private var proteinGoal: Double = 150
    @AppStorage("carbsGoal") private var carbsGoal: Double = 200
    @AppStorage("fatGoal") private var fatGoal: Double = 65
    @State private var showEditGoalSheet = false
    @State private var showLinkSheet = false
    @AppStorage("navigateToDate") private var navigateToDateTimestamp: Double = 0
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var healthKit = HealthKitService.shared
    @AppStorage("dismissedHealthKitDashboardCard") private var dismissedHealthKitCard: Bool = false
    @State private var showAppleHealthSheet = false
    @AppStorage("dashboardSectionOrder") private var dashboardSectionOrderRaw: String = "calories,macros,weeklyTrend,goalStreak,activity"
    @AppStorage("showDashboardCalories") private var showCaloriesCard: Bool = true
    @AppStorage("showDashboardMacros") private var showMacrosCard: Bool = true
    @AppStorage("showDashboardWeeklyTrend") private var showWeeklyTrendCard: Bool = true
    @AppStorage("showDashboardGoalStreak") private var showGoalStreakCard: Bool = true
    @AppStorage("showDashboardActivity") private var showActivityCard: Bool = true
    @State private var showCustomizeDashboardSheet = false
    @State private var selectedDateActiveBurn: Double = 0.0
    @State private var selectedDateBasalBurn: Double = 0.0
    @State private var selectedDateSteps: Int = 0
    @State private var selectedDateWorkouts: [HealthWorkoutItem] = []
    
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
        return activeMeals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .reduce(0) { $0 + $1.totalCalories }
    }
    
    private var todayMeals: [MealEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        return activeMeals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    private var effectiveGoal: Double {
        if healthKit.adjustGoalWithActiveBurn && healthKit.isHealthKitActiveBurnEnabled {
            return dailyGoal + selectedDateActiveBurn
        }
        return dailyGoal
    }
    
    /// Uncapped ratio for selected day's calories card (ring caps at full circle; center label can exceed 100%).
    private var calorieProgressRatio: Double {
        guard effectiveGoal > 0 else { return 0 }
        return todayCalories / effectiveGoal
    }
    
    // Selected day's macros
    private var todayProtein: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        let todayMeals = activeMeals.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
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
        return activeMeals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .compactMap { $0.carbs }
            .reduce(0, +)
    }
    
    private var todayFat: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        return activeMeals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .compactMap { $0.fat }
            .reduce(0, +)
    }

    private var todayFiber: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        return activeMeals
            .filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
            .compactMap { $0.fiber }
            .reduce(0, +)
    }

    private var fiberGoal: Double {
        (dailyGoal / 1000.0) * 14.0
    }
    
    // Weekly nutrient data centered around selectedDate
    private var weeklyDayData: [WeeklyDayNutrientData] {
        let calendar = Calendar.current
        let anchorDate = calendar.startOfDay(for: selectedDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E" // Single letter day (M, T, W, etc.)
        
        var weekData: [WeeklyDayNutrientData] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: anchorDate) else { continue }
            let dayLabel = dateFormatter.string(from: date)
            let isSelected = calendar.isDate(date, inSameDayAs: anchorDate)
            
            let dayMeals = activeMeals.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            let calories = dayMeals.reduce(0.0) { $0 + $1.totalCalories }
            let protein = dayMeals.compactMap { $0.protein }.reduce(0.0, +)
            let carbs = dayMeals.compactMap { $0.carbs }.reduce(0.0, +)
            let fat = dayMeals.compactMap { $0.fat }.reduce(0.0, +)
            let fiber = dayMeals.compactMap { $0.fiber }.reduce(0.0, +)
            
            weekData.append(
                WeeklyDayNutrientData(
                    day: dayLabel,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    fiber: fiber,
                    isToday: isSelected
                )
            )
        }
        
        return weekData.reversed()
    }
    
    // Streak calculation
    private var streakDays: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get all unique dates that have meals
        let mealDates = Set(activeMeals.map { calendar.startOfDay(for: $0.timestamp) })
        
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

    private func checkAndResetSelectedDateIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        
        let lastActiveDate = UserDefaults.standard.object(forKey: "lastActiveDateDashboard") as? Date ?? now
        
        // If the selectedDate matches the lastActiveDate calendar day, it means
        // the user was viewing "today" during the last active session.
        if calendar.isDate(selectedDate, inSameDayAs: lastActiveDate) {
            // If the day has rolled over (selectedDate is not today anymore),
            // reset selectedDate to the new today.
            if !calendar.isDate(selectedDate, inSameDayAs: now) {
                selectedDate = now
            }
        }
        
        // Update the last active date to today
        UserDefaults.standard.set(now, forKey: "lastActiveDateDashboard")
    }

    private var isOverGoal: Bool { todayCalories > effectiveGoal }
    private var remainingUnderGoal: Double { max(0, effectiveGoal - todayCalories) }
    private var amountOverGoal: Double { max(0, todayCalories - effectiveGoal) }

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
                    
                    // Guest Warning Banner (if anonymous)
                    if authViewModel.isAnonymous {
                        HStack(spacing: Constants.Spacing.large) {
                            Image(systemName: "cloud.sun.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.warningAmber)
                            
                            Text("Cloud backup is disabled in Guest Mode.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            
                            Spacer()
                            
                            Button(action: {
                                showLinkSheet = true
                            }) {
                                Text("Sign In")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.primaryGreen)
                            }
                        }
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                        .padding(.vertical, 12)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(Constants.Sizes.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                        )
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    }
                    
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
                                if showCaloriesCard {
                                    TodaysCaloriesCard(
                                        calories: todayCalories,
                                        goal: dailyGoal,
                                        progress: calorieProgressRatio,
                                        activeBurned: healthKit.isHealthKitActiveBurnEnabled ? selectedDateActiveBurn : nil,
                                        adjustGoalWithActiveBurn: healthKit.adjustGoalWithActiveBurn
                                    )
                                }
                                
                                if showMacrosCard {
                                    TodaysMacrosCard(
                                        protein: todayProtein,
                                        carbs: todayCarbs,
                                        fat: todayFat,
                                        fiber: todayFiber,
                                        proteinGoal: proteinGoal,
                                        carbsGoal: carbsGoal,
                                        fatGoal: fatGoal,
                                        fiberGoal: fiberGoal,
                                        onDetailsTapped: {
                                            navigateToDateTimestamp = selectedDate.timeIntervalSince1970
                                            selectedTab = 2
                                        }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Right Column
                            VStack(spacing: Constants.Spacing.extraLarge) {
                                if showWeeklyTrendCard {
                                    ThisWeekCard(
                                        weeklyData: weeklyDayData,
                                        dailyGoal: dailyGoal,
                                        proteinGoal: proteinGoal,
                                        carbsGoal: carbsGoal,
                                        fatGoal: fatGoal,
                                        fiberGoal: fiberGoal
                                    )
                                }
                                
                                if showGoalStreakCard {
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
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    } else {
                        ForEach(orderedDashboardSections) { section in
                            dashboardSectionView(for: section)
                        }
                    }
                    
                    // Today's Meals Section (iPad only)
                    if horizontalSizeClass == .regular {
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
                        .frame(maxWidth: 950)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    // Customize Dashboard Button
                    Button {
                        showCustomizeDashboardSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Customize Dashboard")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Theme.insetBackground(colorScheme: colorScheme))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Theme.cardBorder(colorScheme: colorScheme).opacity(0.8), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Constants.Spacing.medium)
                }
                .padding(.bottom, Constants.Spacing.extraLarge)
            }
            .sheet(isPresented: $showCustomizeDashboardSheet) {
                CustomizeDashboardSheet()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 25, coordinateSpace: .local)
                    .onEnded { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            if value.translation.width < -50 {
                                changeDate(by: 1)
                            } else if value.translation.width > 50 {
                                changeDate(by: -1)
                            }
                        }
                    }
            )
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
            .sheet(isPresented: $showAppleHealthSheet) {
                NavigationStack {
                    AppleHealthSettingsView()
                }
            }
            .sheet(isPresented: $showLinkSheet) {
                LinkAccountView()
                    .environmentObject(authViewModel)
                    .environmentObject(toastManager)
            }
            .onAppear {
                // #region agent log
                DebugLogger.log(location: "DashboardView.swift:onAppear", message: "DashboardView appeared", data: ["mealCount": meals.count], hypothesisId: "B")
                // #endregion
                let now = Date()
                if UserDefaults.standard.object(forKey: "lastActiveDateDashboard") == nil {
                    UserDefaults.standard.set(now, forKey: "lastActiveDateDashboard")
                }
                checkAndResetSelectedDateIfNeeded()
                syncWatchState()
                Task {
                    await refreshActiveBurn()
                }
            }
            .onChange(of: selectedDate) { _, _ in
                Task {
                    await refreshActiveBurn()
                }
            }
            .onChange(of: healthKit.isHealthKitActiveBurnEnabled) { _, _ in
                Task {
                    await refreshActiveBurn()
                }
            }
            .onChange(of: healthKit.activeCaloriesBurned) { _, _ in
                Task {
                    await refreshActiveBurn()
                }
            }
            .onChange(of: meals.count) { oldValue, newValue in
                // #region agent log
                DebugLogger.log(location: "DashboardView.swift:onChange", message: "Meals count changed", data: ["oldCount": oldValue, "newCount": newValue], hypothesisId: "B")
                // #endregion
                syncWatchState()
            }
            .onChange(of: dailyGoal) { _, _ in
                syncWatchState()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkAndResetSelectedDateIfNeeded()
                syncWatchState()
                Task {
                    await refreshActiveBurn()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.NSCalendarDayChanged)) { _ in
                checkAndResetSelectedDateIfNeeded()
                syncWatchState()
                Task {
                    await refreshActiveBurn()
                }
            }
        }
    }
    
    private var orderedDashboardSections: [DashboardSectionType] {
        let keys = dashboardSectionOrderRaw.split(separator: ",").map { String($0) }
        var parsed: [DashboardSectionType] = []
        for key in keys {
            if let section = DashboardSectionType(rawValue: key), !parsed.contains(section) {
                parsed.append(section)
            }
        }
        for section in DashboardSectionType.allCases {
            if !parsed.contains(section) {
                parsed.append(section)
            }
        }
        return parsed
    }
    
    @ViewBuilder
    private func dashboardSectionView(for section: DashboardSectionType) -> some View {
        switch section {
        case .calories:
            if showCaloriesCard {
                TodaysCaloriesCard(
                    calories: todayCalories,
                    goal: dailyGoal,
                    progress: calorieProgressRatio,
                    activeBurned: healthKit.isHealthKitActiveBurnEnabled ? selectedDateActiveBurn : nil,
                    adjustGoalWithActiveBurn: healthKit.adjustGoalWithActiveBurn
                )
                .padding(.horizontal, Constants.Spacing.extraLarge)
            }
        case .macros:
            if showMacrosCard {
                TodaysMacrosCard(
                    protein: todayProtein,
                    carbs: todayCarbs,
                    fat: todayFat,
                    fiber: todayFiber,
                    proteinGoal: proteinGoal,
                    carbsGoal: carbsGoal,
                    fatGoal: fatGoal,
                    fiberGoal: fiberGoal,
                    onDetailsTapped: {
                        navigateToDateTimestamp = selectedDate.timeIntervalSince1970
                        selectedTab = 2
                    }
                )
                .padding(.horizontal, Constants.Spacing.extraLarge)
            }
        case .weeklyTrend:
            if showWeeklyTrendCard {
                ThisWeekCard(
                    weeklyData: weeklyDayData,
                    dailyGoal: dailyGoal,
                    proteinGoal: proteinGoal,
                    carbsGoal: carbsGoal,
                    fatGoal: fatGoal,
                    fiberGoal: fiberGoal
                )
                .padding(.horizontal, Constants.Spacing.extraLarge)
            }
        case .goalStreak:
            if showGoalStreakCard {
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
        case .activity:
            if showActivityCard {
                if healthKit.isHealthKitActiveBurnEnabled {
                    VStack(spacing: Constants.Spacing.large) {
                        Divider()
                            .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        
                        TodaysActivityCard(
                            activeBurn: selectedDateActiveBurn,
                            basalBurn: selectedDateBasalBurn,
                            consumedCalories: todayCalories,
                            steps: selectedDateSteps,
                            workouts: selectedDateWorkouts
                        )
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    }
                    .frame(maxWidth: 950)
                    .frame(maxWidth: .infinity, alignment: .center)
                } else if !healthKit.isAuthorized && !dismissedHealthKitCard {
                    VStack(spacing: Constants.Spacing.large) {
                        Divider()
                            .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        
                        ConnectHealthDiscoveryCard(
                            onConnect: {
                                showAppleHealthSheet = true
                            },
                            onDismiss: {
                                withAnimation(.easeInOut) {
                                    dismissedHealthKitCard = true
                                }
                            }
                        )
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    }
                    .frame(maxWidth: 950)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    private func refreshActiveBurn() async {
        guard healthKit.isHealthKitActiveBurnEnabled else {
            selectedDateActiveBurn = 0.0
            selectedDateBasalBurn = 0.0
            selectedDateSteps = 0
            selectedDateWorkouts = []
            return
        }
        async let burn = healthKit.fetchActiveCalories(for: selectedDate)
        async let steps = healthKit.fetchStepCount(for: selectedDate)
        async let workouts = healthKit.fetchWorkouts(for: selectedDate)
        async let basal = healthKit.fetchBasalCalories(for: selectedDate)
        
        let (b, s, w, basalVal) = await (burn, steps, workouts, basal)
        selectedDateActiveBurn = b
        selectedDateSteps = s
        selectedDateWorkouts = w
        selectedDateBasalBurn = basalVal
    }
    
    private func syncWatchState() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todaysMeals = activeMeals.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
        let cals = todaysMeals.reduce(0) { $0 + $1.totalCalories }
        let p = todaysMeals.compactMap(\.protein).reduce(0, +)
        let c = todaysMeals.compactMap(\.carbs).reduce(0, +)
        let f = todaysMeals.compactMap(\.fat).reduce(0, +)
        let fib = todaysMeals.compactMap(\.fiber).reduce(0, +)
        
        WatchSyncService.shared.syncToWatch(
            todayCalories: cals,
            dailyGoal: dailyGoal,
            protein: p,
            carbs: c,
            fat: f,
            fiber: fib,
            savedMeals: savedMeals
        )
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
