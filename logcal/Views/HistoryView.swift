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
    
    var body: some View {
        NavigationView {
            List(selection: $selectedMeals) {
                ForEach(meals) { meal in
                    if editMode == .active {
                        MealRowView(meal: meal)
                            .tag(meal.id)
                    } else {
                        NavigationLink(destination: MealDetailView(meal: meal)) {
                            MealRowView(meal: meal)
                        }
                    }
                }
                .onDelete(perform: deleteMeals)
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if editMode == .active {
                        Button("Cancel") {
                            withAnimation {
                                editMode = .inactive
                                selectedMeals.removeAll()
                            }
                            print("DEBUG: Edit mode cancelled")
                        }
                    } else {
                        if !meals.isEmpty {
                            Button("Edit") {
                                withAnimation {
                                    editMode = .active
                                }
                                print("DEBUG: Edit mode activated")
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
        }
    }
    
    private func deleteMeals(at offsets: IndexSet) {
        print("DEBUG: Deleting meals at offsets: \(offsets)")
        for index in offsets {
            let meal = meals[index]
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
                    
                    Text(meal.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
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

