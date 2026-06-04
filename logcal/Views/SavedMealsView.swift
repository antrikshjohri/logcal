//
//  SavedMealsView.swift
//  logcal
//

import SwiftUI
import SwiftData

struct SavedMealsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var cloudSyncService: CloudSyncService
    @Query(sort: \SavedMeal.displayOrder, order: .forward) private var savedMeals: [SavedMeal]
    @State private var mealBeingRenamed: SavedMeal?
    @State private var mealPendingDeletion: SavedMeal?
    @State private var renameText = ""

    var body: some View {
        List {
            if savedMeals.isEmpty {
                ContentUnavailableView(
                    "No Favourites",
                    systemImage: "bookmark",
                    description: Text("Save meals after logging them to make repeat logging faster.")
                )
            } else {
                ForEach(savedMeals) { savedMeal in
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        HStack(alignment: .firstTextBaseline, spacing: Constants.Spacing.small) {
                            Text(savedMeal.title)
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)

                            Button {
                                renameText = savedMeal.title
                                mealBeingRenamed = savedMeal
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Theme.primaryGreen)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Rename favourite meal")

                            Spacer()

                            Text("\(Int(savedMeal.totalCalories)) cal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button(role: .destructive) {
                                mealPendingDeletion = savedMeal
                            } label: {
                                Image(systemName: "trash")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.red)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete favourite meal")
                        }

                        HStack(spacing: 6) {
                            Text(savedMeal.mealType.capitalized)
                                .font(.caption)
                                .foregroundColor(Theme.primaryGreen)
                            
                            if let p = savedMeal.protein, let c = savedMeal.carbs, let f = savedMeal.fat,
                               p > 0 || c > 0 || f > 0 {
                                Text("·")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("P: \(Int(p))g  C: \(Int(c))g  F: \(Int(f))g")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let response = savedMeal.response {
                            Text(response.items.prefix(3).map(\.name).joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, Constants.Spacing.small)
                    .listRowBackground(Theme.cardBackground(colorScheme: colorScheme))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            mealPendingDeletion = savedMeal
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            renameText = savedMeal.title
                            mealBeingRenamed = savedMeal
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(Theme.primaryGreen)
                    }
                }
                .onMove(perform: moveSavedMeals)
            }
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 650 : .infinity)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Theme.backgroundColor(colorScheme: colorScheme))
        .scrollContentBackground(.hidden)
        .navigationTitle("Favourites")
        .toolbar {
            EditButton()
        }
        .alert("Rename Favourite Meal", isPresented: Binding(
            get: { mealBeingRenamed != nil },
            set: { if !$0 { mealBeingRenamed = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                mealBeingRenamed = nil
            }
            Button("Save") {
                renameSelectedMeal()
            }
        }
        .alert("Delete Favourite Meal", isPresented: Binding(
            get: { mealPendingDeletion != nil },
            set: { if !$0 { mealPendingDeletion = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                mealPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                deletePendingMeal()
            }
        } message: {
            Text("Are you sure you want to delete this favourite meal? This action cannot be undone.")
        }
    }

    private func renameSelectedMeal() {
        guard let savedMeal = mealBeingRenamed else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            mealBeingRenamed = nil
            return
        }

        savedMeal.title = String(trimmed.prefix(140))
        savedMeal.updatedAt = Date()
        try? modelContext.save()
        mealBeingRenamed = nil
        
        Task {
            await cloudSyncService.syncSavedMealsToCloud(modelContext: modelContext)
        }
    }

    private func delete(_ savedMeal: SavedMeal) {
        modelContext.delete(savedMeal)
        try? modelContext.save()
        
        Task {
            await cloudSyncService.syncSavedMealsToCloud(modelContext: modelContext)
        }
    }

    private func deletePendingMeal() {
        guard let savedMeal = mealPendingDeletion else { return }
        delete(savedMeal)
        mealPendingDeletion = nil
    }

    private func moveSavedMeals(from source: IndexSet, to destination: Int) {
        var revisedMeals = Array(savedMeals)
        revisedMeals.move(fromOffsets: source, toOffset: destination)
        
        for index in 0..<revisedMeals.count {
            revisedMeals[index].displayOrder = index
        }
        
        try? modelContext.save()
        
        Task {
            await cloudSyncService.syncSavedMealsToCloud(modelContext: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        SavedMealsView()
    }
    .modelContainer(for: [MealEntry.self, SavedMeal.self])
    .environmentObject(CloudSyncService())
}
