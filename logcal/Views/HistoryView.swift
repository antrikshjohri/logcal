//
//  HistoryView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct HistoryView: View {
    @Query(sort: \MealEntry.timestamp, order: .reverse) private var meals: [MealEntry]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var cloudSyncService: CloudSyncService
    @Binding var selectedTab: Int
    @State private var editMode: EditMode = .inactive
    @State private var selectedMeals: Set<UUID> = []
    @State private var showClearAllAlert = false
    @State private var expandedDates: Set<Date> = []
    @State private var savedExpandedDates: Set<Date> = []
    @State private var hasInitialized: Bool = false
    @State private var searchText = ""
    @AppStorage("navigateToDate") private var navigateToDateTimestamp: Double = 0
    
    // Group meals by date
    private var groupedMeals: [(date: Date, meals: [MealEntry], totalCalories: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredMeals) { meal in
            calendar.startOfDay(for: meal.timestamp)
        }
        
        return grouped.map { (date, meals) in
            let total = meals.reduce(0) { $0 + $1.totalCalories }
            // Sort meals within each day by createdAt (most recently added first)
            let sortedMeals = meals.sorted { $0.effectiveCreatedAt > $1.effectiveCreatedAt }
            return (date: date, meals: sortedMeals, totalCalories: total)
        }
        .sorted { date1, date2 in
            // Today always comes first
            if isToday(date1.date) { return true }
            if isToday(date2.date) { return false }
            // Then sort by newest first
            return date1.date > date2.date
        }
    }
    
    // Filter meals by search text
    private var filteredMeals: [MealEntry] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return meals
        } else {
            return meals.filter { meal in
                meal.foodText.localizedCaseInsensitiveContains(trimmed)
            }
        }
    }
    
    // Get today's date (start of day)
    private var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    // Check if a date is today
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    // Initialize expanded dates - expand the two most recent day cards by default.
    private func initializeExpandedDates() {
        guard !hasInitialized else {
            return
        }
        
        hasInitialized = true  // Mark as initialized regardless of whether there are meals
        
        expandedDates.formUnion(allDates.prefix(2).map(\.date))
    }
    
    // All dates including Today (even if Today has no meals)
    private var allDates: [(date: Date, meals: [MealEntry], totalCalories: Double)] {
        var dates = groupedMeals
        
        // If Today is not in groupedMeals, add it with empty meals (only if not searching)
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if !dates.contains(where: { isToday($0.date) }) {
                dates.insert((date: todayDate, meals: [], totalCalories: 0), at: 0)
            }
        }
        
        // Ensure Today is always first
        return dates.sorted { date1, date2 in
            if isToday(date1.date) { return true }
            if isToday(date2.date) { return false }
            return date1.date > date2.date
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if meals.isEmpty {
                    VStack(spacing: 24) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Theme.softAccentBackground(colorScheme: colorScheme))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "calendar")
                                .font(.system(size: 44))
                                .foregroundColor(Theme.primaryGreen)
                        }
                        
                        VStack(spacing: 8) {
                            Text("No Calorie History")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            
                            Text("Once you start logging meals from the Log tab, they will appear here.")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        Button(action: {
                            selectedTab = 1
                        }) {
                            Text("Go to Log Tab")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background(Theme.primaryGreen)
                                .cornerRadius(25)
                        }
                        
                        Spacer()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.backgroundColor(colorScheme: colorScheme))
                } else if filteredMeals.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        Text("No results for \"\(searchText)\"")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        Text("Check spelling or try a different search term.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        Spacer()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.backgroundColor(colorScheme: colorScheme))
                } else {
                    ScrollView {
                        LazyVStack(spacing: Constants.Spacing.large) {
                            ForEach(Array(allDates.enumerated()), id: \.element.date) { index, dayGroup in
                                DayCardView(
                                    dayGroup: dayGroup,
                                    isExpanded: Binding(
                                        get: { !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || expandedDates.contains(dayGroup.date) },
                                        set: { isExpanded in
                                            if isExpanded {
                                                expandedDates.insert(dayGroup.date)
                                            } else {
                                                expandedDates.remove(dayGroup.date)
                                            }
                                        }
                                    ),
                                    editMode: $editMode,
                                    selectedMeals: $selectedMeals,
                                    isToday: isToday(dayGroup.date),
                                    navigateToDateTimestamp: $navigateToDateTimestamp,
                                    selectedTab: $selectedTab
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, Constants.Spacing.large)
                    }
                    .background(Theme.backgroundColor(colorScheme: colorScheme))
                    .refreshable {
                        await refreshFromCloud()
                    }
                }
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search meals...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if editMode == .active {
                        Button("Cancel") {
                            expandedDates = savedExpandedDates
                            editMode = .inactive
                            selectedMeals.removeAll()
                        }
                        .foregroundColor(Theme.primaryGreen)
                    } else {
                        if !meals.isEmpty {
                            Button("Edit") {
                                savedExpandedDates = expandedDates
                                editMode = .active
                            }
                            .foregroundColor(Theme.primaryGreen)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if editMode == .active {
                        if !selectedMeals.isEmpty {
                            Button("Delete (\(selectedMeals.count))") {
                                deleteSelectedMeals()
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        if !meals.isEmpty {
                            Button("Clear All") {
                                showClearAllAlert = true
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .navigationDestination(for: MealEntry.self) { meal in
                MealEditView(meal: meal)
            }
            .overlay {
                if cloudSyncService.isSyncing {
                    VStack(spacing: Constants.Spacing.medium) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading your meals...")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.backgroundColor(colorScheme: colorScheme).opacity(0.95))
                }
            }
            .alert("Clear All Logs", isPresented: $showClearAllAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllMeals()
                }
            } message: {
                Text("Are you sure you want to delete all \(meals.count) meal logs? This action cannot be undone.")
            }
            .onAppear {
                if !hasInitialized {
                    initializeExpandedDates()
                }
                
                if navigateToDateTimestamp > 0 {
                    let dateToNavigate = Date(timeIntervalSince1970: navigateToDateTimestamp)
                    let calendar = Calendar.current
                    let targetDate = calendar.startOfDay(for: dateToNavigate)
                    expandedDates.insert(targetDate)
                    navigateToDateTimestamp = 0
                }
                
                if meals.isEmpty && !cloudSyncService.isSyncing {
                    if let user = Auth.auth().currentUser, !user.isAnonymous {
                        print("DEBUG: History tab appeared with no meals, triggering auto-refresh...")
                        Task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            await refreshFromCloud()
                        }
                    }
                }
            }
            .onChange(of: navigateToDateTimestamp) { oldValue, newValue in
                if newValue > 0 {
                    let dateToNavigate = Date(timeIntervalSince1970: newValue)
                    let calendar = Calendar.current
                    let targetDate = calendar.startOfDay(for: dateToNavigate)
                    expandedDates.insert(targetDate)
                    navigateToDateTimestamp = 0
                }
            }
            .onChange(of: cloudSyncService.lastSyncTime) { oldValue, newValue in
                print("DEBUG: [HistoryView] Sync completed, meal count: \(meals.count)")
            }
            .onChange(of: Auth.auth().currentUser?.uid) { oldValue, newValue in
                print("DEBUG: [HistoryView] User changed, refreshing...")
                if newValue != nil && newValue != oldValue {
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await refreshFromCloud()
                    }
                }
            }
            .onChange(of: groupedMeals.count) { oldValue, newValue in
                if !hasInitialized && newValue > 0 {
                    initializeExpandedDates()
                }
            }
            .onChange(of: meals.count) { oldValue, newValue in
                if newValue > oldValue && !hasInitialized {
                    initializeExpandedDates()
                }
            }
        }
    }
    
    private func deleteMeals(at offsets: IndexSet, in dayMeals: [MealEntry]) {
        for index in offsets {
            let meal = dayMeals[index]
            Task {
                await cloudSyncService.deleteMealFromCloud(meal)
            }
            modelContext.delete(meal)
        }
        
        try? modelContext.save()
    }
    
    private func deleteSelectedMeals() {
        let mealsToDelete = meals.filter { selectedMeals.contains($0.id) }
        
        for meal in mealsToDelete {
            Task {
                await cloudSyncService.deleteMealFromCloud(meal)
            }
            modelContext.delete(meal)
        }
        
        selectedMeals.removeAll()
        
        do {
            try modelContext.save()
            expandedDates = savedExpandedDates
            editMode = .inactive
        } catch {
            // Error saving
        }
    }
    
    private func clearAllMeals() {
        for meal in meals {
            Task {
                await cloudSyncService.deleteMealFromCloud(meal)
            }
            modelContext.delete(meal)
        }
        
        try? modelContext.save()
    }
    
    private func refreshFromCloud() async {
        print("DEBUG: Refresh triggered from HistoryView")
        await cloudSyncService.syncFromCloud(modelContext: modelContext)
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

struct MealRowView: View {
    @Environment(\.colorScheme) var colorScheme
    let meal: MealEntry
    
    private func mealTypeIcon(for type: String) -> String {
        switch type.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.stars.fill"
        default: return "leaf.fill"
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 6) {
                    Text(meal.foodText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .lineLimit(1)
                    
                    if meal.hasImageValue {
                        Image(systemName: "photo")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.primaryGreen)
                            .padding(4)
                            .background(Theme.softAccentBackground(colorScheme: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                
                HStack(spacing: 10) {
                    // Meal Type Badge
                    HStack(spacing: 3) {
                        Image(systemName: mealTypeIcon(for: meal.mealType))
                            .font(.system(size: 9, weight: .bold))
                        Text(meal.mealType.capitalized)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.softAccentBackground(colorScheme: colorScheme))
                    .foregroundColor(Theme.primaryGreen)
                    .cornerRadius(6)
                    .fixedSize(horizontal: true, vertical: false)
                    
                    // Micro macros
                    if let protein = meal.protein, let carbs = meal.carbs, let fat = meal.fat {
                        HStack(spacing: 4) {
                            Text("P: \(Int(protein))g")
                                .foregroundColor(Theme.proteinColor)
                            Text("·")
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            Text("C: \(Int(carbs))g")
                                .foregroundColor(Theme.carbsColor)
                            Text("·")
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            Text("F: \(Int(fat))g")
                                .foregroundColor(Theme.fatColor)
                        }
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
            
            Spacer()
            
            Text("\(Int(meal.totalCalories)) kcal")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Theme.primaryGreen)
        }
        .padding(.vertical, 10)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DayCardView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("dailyGoal") private var dailyGoal: Double = 2000
    let dayGroup: (date: Date, meals: [MealEntry], totalCalories: Double)
    @Binding var isExpanded: Bool
    @Binding var editMode: EditMode
    @Binding var selectedMeals: Set<UUID>
    let isToday: Bool
    @Binding var navigateToDateTimestamp: Double
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        if isToday {
                            Circle()
                                .fill(Theme.primaryGreen)
                                .frame(width: 8, height: 8)
                        }
                        Text(DateFormatterCache.formatDateHeader(dayGroup.date))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    }
                    
                    Spacer()
                    
                    if !dayGroup.meals.isEmpty {
                        let isOverGoal = dayGroup.totalCalories > dailyGoal
                        HStack(spacing: 4) {
                            Image(systemName: isOverGoal ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(isOverGoal ? Theme.warningAmber : Theme.primaryGreen)
                            
                            Text("\(Int(dayGroup.totalCalories)) kcal")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(isOverGoal ? Theme.warningAmber : Theme.primaryGreen)
                        }
                    } else if isToday {
                        Text("0 kcal")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            if isExpanded {
                if dayGroup.meals.isEmpty && isToday {
                    // Empty state
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Theme.softAccentBackground(colorScheme: colorScheme))
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: "calendar")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.primaryGreen)
                        }
                        
                        VStack(spacing: 4) {
                            Text("No meals logged today")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            
                            Text("Start tracking your calories")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        }
                        
                        Button(action: {
                            navigateToDateTimestamp = Date().timeIntervalSince1970
                            selectedTab = 1
                        }) {
                            Text("Log your first meal")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Theme.primaryGreen)
                                .cornerRadius(22)
                                .shadow(color: Theme.primaryGreen.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 48)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.bottom, 8)
                } else {
                    // Meals list
                    let dailyP = dayGroup.meals.reduce(0.0) { $0 + ($1.protein ?? 0) }
                    let dailyC = dayGroup.meals.reduce(0.0) { $0 + ($1.carbs ?? 0) }
                    let dailyF = dayGroup.meals.reduce(0.0) { $0 + ($1.fat ?? 0) }
                    
                    VStack(spacing: 0) {
                        if dailyP > 0 || dailyC > 0 || dailyF > 0 {
                            HStack {
                                Text("Day Total")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                
                                Spacer()
                                
                                MacrosCaptionLine(
                                    protein: dailyP,
                                    carbs: dailyC,
                                    fat: dailyF,
                                    font: .system(size: 12, weight: .bold, design: .rounded)
                                )
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.insetBackground(colorScheme: colorScheme))
                            
                            Divider()
                                .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                        }
                        
                        ForEach(Array(dayGroup.meals.enumerated()), id: \.element.id) { mealIndex, meal in
                            VStack(spacing: 0) {
                                if editMode == .active {
                                    Button(action: {
                                        if selectedMeals.contains(meal.id) {
                                            selectedMeals.remove(meal.id)
                                        } else {
                                            selectedMeals.insert(meal.id)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: selectedMeals.contains(meal.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedMeals.contains(meal.id) ? Theme.primaryGreen : Theme.mutedText(colorScheme: colorScheme))
                                            MealRowView(meal: meal)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    NavigationLink(value: meal) {
                                        MealRowView(meal: meal)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                if mealIndex < dayGroup.meals.count - 1 {
                                    Divider()
                                        .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .background(Theme.cardBackground(colorScheme: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isToday ? Theme.primaryGreen.opacity(0.25) : Theme.cardBorder(colorScheme: colorScheme),
                    lineWidth: isToday ? 1.5 : 1
                )
        )
        .cornerRadius(16)
        .shadow(color: Theme.shadowColor(colorScheme: colorScheme), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    HistoryView(selectedTab: .constant(2))
        .modelContainer(for: [MealEntry.self, SavedMeal.self])
}
