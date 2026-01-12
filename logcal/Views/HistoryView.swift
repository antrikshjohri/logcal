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
    @EnvironmentObject var cloudSyncService: CloudSyncService
    @Binding var selectedTab: Int
    @State private var editMode: EditMode = .inactive
    @State private var selectedMeals: Set<UUID> = []
    @State private var showClearAllAlert = false
    @State private var expandedDates: Set<Date> = []
    @State private var savedExpandedDates: Set<Date> = []
    @State private var hasInitialized: Bool = false
    @AppStorage("navigateToDate") private var navigateToDateTimestamp: Double = 0
    
    // Group meals by date
    private var groupedMeals: [(date: Date, meals: [MealEntry], totalCalories: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: meals) { meal in
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
    
    // Get today's date (start of day)
    private var todayDate: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    // Check if a date is today
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    // Initialize expanded dates - expand Today by default on first launch
    private func initializeExpandedDates() {
        guard !hasInitialized else {
            return
        }
        
        hasInitialized = true  // Mark as initialized regardless of whether there are meals
        
        // Expand Today by default on first launch
        expandedDates.insert(todayDate)
    }
    
    // All dates including Today (even if Today has no meals)
    private var allDates: [(date: Date, meals: [MealEntry], totalCalories: Double)] {
        var dates = groupedMeals
        
        // If Today is not in groupedMeals, add it with empty meals
        if !dates.contains(where: { isToday($0.date) }) {
            dates.insert((date: todayDate, meals: [], totalCalories: 0), at: 0)
        }
        
        // Ensure Today is always first
        return dates.sorted { date1, date2 in
            if isToday(date1.date) { return true }
            if isToday(date2.date) { return false }
            return date1.date > date2.date
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                ForEach(Array(allDates.enumerated()), id: \.element.date) { index, dayGroup in
                        DayCardView(
                            dayGroup: dayGroup,
                            isExpanded: Binding(
                        get: { expandedDates.contains(dayGroup.date) },
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
                .padding(.horizontal, 28)
                .padding(.vertical, Constants.Spacing.large)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .refreshable {
                // Manual refresh - sync from cloud
                await refreshFromCloud()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if editMode == .active {
                        Button("Cancel") {
                            withAnimation {
                                // Restore previous expanded state
                                expandedDates = savedExpandedDates
                                editMode = .inactive
                                selectedMeals.removeAll()
                            }
                        }
                    } else {
                        if !meals.isEmpty {
                            Button("Edit") {
                                withAnimation {
                                    // Save current expanded state
                                    savedExpandedDates = expandedDates
                                    // Expand all sections for editing
                                    expandedDates = Set(groupedMeals.map { $0.date })
                                    editMode = .active
                                }
                            }
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
            .overlay {
                // Show loading indicator when syncing
                if cloudSyncService.isSyncing {
                    VStack(spacing: Constants.Spacing.medium) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading your meals...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, Constants.Spacing.small)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.9))
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
                // Only initialize on first appearance (app launch)
                if !hasInitialized {
                    initializeExpandedDates()
                }
                
                // Auto-refresh when History tab appears if:
                // 1. We have no meals, AND
                // 2. User is signed in (not anonymous), AND
                // 3. Not currently syncing
                // This ensures data loads when user navigates to History after sign-in
                if meals.isEmpty && !cloudSyncService.isSyncing {
                    // Check if user is signed in (only sync for signed-in users)
                    if let user = Auth.auth().currentUser, !user.isAnonymous {
                        print("DEBUG: History tab appeared with no meals, triggering auto-refresh...")
                        Task {
                            // Small delay to ensure view is ready
                            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                            await refreshFromCloud()
                        }
                    }
                }
            }
            .onChange(of: cloudSyncService.lastSyncTime) { oldValue, newValue in
                print("DEBUG: [HistoryView] Sync completed, meal count: \(meals.count)")
            }
            .onChange(of: Auth.auth().currentUser?.uid) { oldValue, newValue in
                print("DEBUG: [HistoryView] User changed from \(oldValue ?? "nil") to \(newValue ?? "nil"), meal count: \(meals.count)")
                // When user changes, refresh from cloud to get new user's data
                if newValue != nil && newValue != oldValue {
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds delay
                        await refreshFromCloud()
                    }
                }
            }
            .onChange(of: groupedMeals.count) { oldValue, newValue in
                // Only initialize if we haven't initialized yet and there are new meals
                if !hasInitialized && newValue > 0 {
                    initializeExpandedDates()
                }
            }
            .onChange(of: meals.count) { oldValue, newValue in
                // When meals count changes, ensure expanded dates are initialized
                if newValue > oldValue && !hasInitialized {
                    initializeExpandedDates()
                }
            }
        }
    }
    
    private func deleteMeals(at offsets: IndexSet, in dayMeals: [MealEntry]) {
        for index in offsets {
            let meal = dayMeals[index]
            // Delete from cloud
            Task {
                await cloudSyncService.deleteMealFromCloud(meal)
            }
            modelContext.delete(meal)
        }
        
        do {
            try modelContext.save()
        } catch {
            // Error saving - SwiftData will handle persistence
        }
    }
    
    
    private func deleteSelectedMeals() {
        let mealsToDelete = meals.filter { selectedMeals.contains($0.id) }
        
        for meal in mealsToDelete {
            // Delete from cloud
            Task {
                await cloudSyncService.deleteMealFromCloud(meal)
            }
            modelContext.delete(meal)
        }
        
        selectedMeals.removeAll()
        
        do {
            try modelContext.save()
            withAnimation {
                // Restore previous expanded state
                expandedDates = savedExpandedDates
                editMode = .inactive
            }
        } catch {
            // Error saving - SwiftData will handle persistence
        }
    }
    
    private func clearAllMeals() {
        for meal in meals {
            // Delete from cloud
            Task {
                await cloudSyncService.deleteMealFromCloud(meal)
            }
            modelContext.delete(meal)
        }
        
        do {
            try modelContext.save()
        } catch {
            // Error saving - SwiftData will handle persistence
        }
    }
    
    private func refreshFromCloud() async {
        print("DEBUG: Refresh triggered from HistoryView")
        await cloudSyncService.syncFromCloud(modelContext: modelContext)
        
        // Wait a moment for @Query to update with new data
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
}

struct MealRowView: View {
    let meal: MealEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                Text(meal.foodText)
                    .font(.headline)
                        .foregroundColor(.primary)
                    .lineLimit(2)
                    
                    // Show image indicator if image was used
                    if meal.hasImageValue {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.primaryBlue)
                    }
                }
                
                HStack {
                    Text(meal.mealType.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Constants.Colors.badgeBackground)
                        .cornerRadius(Constants.Spacing.small)
                    
                    Text(meal.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Macros (compact view)
                    if let protein = meal.protein, let carbs = meal.carbs, let fat = meal.fat {
                        HStack(spacing: 4) {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(protein))P")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(carbs))C")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(fat))F")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            Text("\(Int(meal.totalCalories)) cal")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.primaryBlue)
        }
        .padding(.vertical, 10)
    }
}

// Day Card View - Individual card for each day
struct DayCardView: View {
    @Environment(\.colorScheme) var colorScheme
    let dayGroup: (date: Date, meals: [MealEntry], totalCalories: Double)
    @Binding var isExpanded: Bool
    @Binding var editMode: EditMode
    @Binding var selectedMeals: Set<UUID>
    let isToday: Bool
    @Binding var navigateToDateTimestamp: Double
    @Binding var selectedTab: Int
    
    private func cardBackground(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: 0.15)
            : Color.white
    }
    
    private func cardBorder(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.gray.opacity(0.2)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(DateFormatterCache.formatDateHeader(dayGroup.date))
                        .font(.headline)
                    Spacer()
                    if !dayGroup.meals.isEmpty {
                        Text("\(Int(dayGroup.totalCalories)) cal")
                            .font(.headline)
                            .foregroundColor(Constants.Colors.primaryBlue)
                    } else if isToday {
                        Text("0 cal")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(Constants.Spacing.large)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            if isExpanded {
                if dayGroup.meals.isEmpty && isToday {
                    // Empty state
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Constants.Colors.primaryBlue.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "calendar")
                                .font(.system(size: 40))
                                .foregroundColor(Constants.Colors.primaryBlue)
                        }
                        
                        VStack(spacing: 4) {
                            Text("No meals logged today")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Start tracking your calories")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            navigateToDateTimestamp = Date().timeIntervalSince1970
                            selectedTab = 1
                        }) {
                            Text("Log your first meal")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Constants.Colors.primaryBlue)
                                .cornerRadius(25)
                        }
                        .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.bottom, Constants.Spacing.large)
                } else {
                    // Meals list
                    VStack(spacing: 0) {
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
                                                .foregroundColor(selectedMeals.contains(meal.id) ? Constants.Colors.primaryBlue : .secondary)
                                            MealRowView(meal: meal)
                                        }
                                        .padding(.horizontal, Constants.Spacing.large)
                                        .padding(.vertical, Constants.Spacing.small)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    NavigationLink(destination: MealEditView(meal: meal)) {
                                        MealRowView(meal: meal)
                                            .padding(.horizontal, Constants.Spacing.large)
                                            .padding(.vertical, Constants.Spacing.small)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                if mealIndex < dayGroup.meals.count - 1 {
                                    Divider()
                                        .padding(.leading, Constants.Spacing.large)
                                }
                            }
                        }
                    }
                    .padding(.bottom, Constants.Spacing.large)
                }
            }
        }
        .background(cardBackground(colorScheme: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                .stroke(cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
        )
        .cornerRadius(Constants.Sizes.largeCornerRadius)
    }
}

#Preview {
    HistoryView(selectedTab: .constant(2))
        .modelContainer(for: MealEntry.self)
}

