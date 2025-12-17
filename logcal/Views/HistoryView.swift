//
//  HistoryView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \MealEntry.timestamp, order: .reverse) private var meals: [MealEntry]
    @Environment(\.modelContext) private var modelContext
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
            print("DEBUG: Already initialized, skipping")
            return
        }
        
        if let latestDate = groupedMeals.first?.date {
            expandedDates = [latestDate]
            hasInitialized = true
            print("DEBUG: Initialized with latest date expanded: \(latestDate)")
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
                            print("DEBUG: Toggled date \(dayGroup.date): \(isExpanded)")
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
                            Text(formatDateHeader(dayGroup.date))
                                .font(.headline)
                            Spacer()
                            Text("\(Int(dayGroup.totalCalories)) cal")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("History")
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
                            print("DEBUG: Edit mode cancelled, restored expanded dates")
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
                                print("DEBUG: Edit mode activated, all sections expanded")
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
                if meals.isEmpty {
                    VStack {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
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
                } else {
                    print("DEBUG: View appeared, maintaining current expanded state")
                }
            }
            .onChange(of: groupedMeals.count) { oldValue, newValue in
                // Only initialize if we haven't initialized yet and there are new meals
                if !hasInitialized && newValue > 0 {
                    initializeExpandedDates()
                }
            }
        }
    }
    
    private func deleteMeals(at offsets: IndexSet, in dayMeals: [MealEntry]) {
        print("DEBUG: Deleting meals at offsets: \(offsets)")
        for index in offsets {
            let meal = dayMeals[index]
            modelContext.delete(meal)
            print("DEBUG: Deleted meal: \(meal.foodText)")
        }
        
        do {
            try modelContext.save()
            print("DEBUG: Successfully saved after deletion")
        } catch {
            print("DEBUG: Error saving after deletion: \(error.localizedDescription)")
        }
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func deleteSelectedMeals() {
        print("DEBUG: Deleting \(selectedMeals.count) selected meals")
        let mealsToDelete = meals.filter { selectedMeals.contains($0.id) }
        
        for meal in mealsToDelete {
            modelContext.delete(meal)
            print("DEBUG: Deleted meal: \(meal.foodText)")
        }
        
        selectedMeals.removeAll()
        
        do {
            try modelContext.save()
            print("DEBUG: Successfully saved after deletion")
            withAnimation {
                // Restore previous expanded state
                expandedDates = savedExpandedDates
                editMode = .inactive
            }
        } catch {
            print("DEBUG: Error saving after deletion: \(error.localizedDescription)")
        }
    }
    
    private func clearAllMeals() {
        print("DEBUG: Clearing all \(meals.count) meals")
        for meal in meals {
            modelContext.delete(meal)
        }
        
        do {
            try modelContext.save()
            print("DEBUG: Successfully cleared all meals")
        } catch {
            print("DEBUG: Error saving after clearing all: \(error.localizedDescription)")
        }
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
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(meal.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(Int(meal.totalCalories)) cal")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: MealEntry.self)
}

