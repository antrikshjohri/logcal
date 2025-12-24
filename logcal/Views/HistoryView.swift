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
    @State private var editMode: EditMode = .inactive
    @State private var selectedMeals: Set<UUID> = []
    @State private var showClearAllAlert = false
    @State private var expandedDates: Set<Date> = []
    @State private var savedExpandedDates: Set<Date> = []
    @State private var hasInitialized: Bool = false
    
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
        .sorted { $0.date > $1.date } // Sort days (newest first)
    }
    
    // Initialize expanded dates - only latest day expanded by default (only on first launch)
    private func initializeExpandedDates() {
        guard !hasInitialized else {
            return
        }
        
        hasInitialized = true  // Mark as initialized regardless of whether there are meals
        
        if let latestDate = groupedMeals.first?.date {
            expandedDates = [latestDate]
        }
    }
    
    var body: some View {
        NavigationView {
            List(selection: $selectedMeals) {
                ForEach(groupedMeals, id: \.date) { dayGroup in
                    DisclosureGroup(isExpanded: Binding(
                        get: { expandedDates.contains(dayGroup.date) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedDates.insert(dayGroup.date)
                            } else {
                                expandedDates.remove(dayGroup.date)
                            }
                        }
                    )) {
                        ForEach(dayGroup.meals) { meal in
                            if editMode == .active {
                                MealRowView(meal: meal)
                                    .tag(meal.id)
                            } else {
                                NavigationLink(destination: MealDetailView(meal: meal)) {
                                    MealRowView(meal: meal)
                                }
                            }
                        }
                        .onDelete { offsets in
                            deleteMeals(at: offsets, in: dayGroup.meals)
                        }
                    } label: {
                        HStack {
                            Text(DateFormatterCache.formatDateHeader(dayGroup.date))
                                .font(.headline)
                            Spacer()
                            Text("\(Int(dayGroup.totalCalories)) cal")
                                .font(.headline)
                                .foregroundColor(Constants.Colors.primaryBlue)
                        }
                    }
                }
            }
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
                } else if meals.isEmpty {
                    // Show empty state only when not syncing
                    VStack {
                        Image(systemName: "fork.knife")
                            .font(.system(size: Constants.Sizes.emptyStateIcon))
                            .foregroundColor(Constants.Colors.primaryGray)
                        Text("No meals logged yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
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
        print("DEBUG: Manual refresh triggered from HistoryView")
        await cloudSyncService.syncFromCloud(modelContext: modelContext)
    }
}

struct MealRowView: View {
    let meal: MealEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.foodText)
                    .font(.headline)
                    .lineLimit(2)
                
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
                }
            }
            
            Spacer()
            
            Text("\(Int(meal.totalCalories)) cal")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Constants.Colors.primaryBlue)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: MealEntry.self)
}

