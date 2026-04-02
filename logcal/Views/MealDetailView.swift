//
//  MealDetailView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import UIKit

struct MealDetailView: View {
    let meal: MealEntry
    @Environment(\.modelContext) private var modelContext
    @StateObject private var appConfigService = AppConfigService()
    @State private var showEditSheet: Bool = false
    @State private var quickEditPrompt = ""
    @State private var isRefiningQuickEdit = false
    @State private var quickEditError: String?
    @State private var showUpdateRequiredAlert = false
    private let cloudSyncService = CloudSyncService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // What you ate + quick fix (same section as MealEditView label)
                VStack(alignment: .leading, spacing: 12) {
                    Text("What you ate")
                        .font(.headline)
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text(meal.foodText)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if meal.hasImageValue {
                            Image(systemName: "photo.fill")
                                .font(.title3)
                                .foregroundColor(Constants.Colors.primaryBlue)
                        }
                    }
                    
                    HStack {
                        Text(meal.mealType.capitalized)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text(meal.timestamp, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(meal.timestamp, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if meal.response != nil {
                        QuickEditMealSection(
                            prompt: $quickEditPrompt,
                            isLoading: isRefiningQuickEdit,
                            errorMessage: quickEditError
                        ) {
                            Task {
                                await runQuickRefine()
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Constants.Colors.secondaryBackground)
                .cornerRadius(Constants.Sizes.largeCornerRadius)
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Total calories and macros
                VStack(alignment: .leading, spacing: 12) {
                    Text("Total Calories")
                        .font(.headline)
                    Text("\(Int(meal.totalCalories))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)
                    
                    // Macros row
                    if let protein = meal.protein, let carbs = meal.carbs, let fat = meal.fat {
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(protein))g")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(carbs))g")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Carbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(fat))g")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Fat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
                
                Divider()
                
                // Items breakdown
                if let response = meal.response {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Breakdown")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(Array(response.items.enumerated()), id: \.offset) { index, item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(item.name)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("\(Int(item.calories)) cal")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                
                                Text("Quantity: \(item.quantity)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Macros per item
                                if let protein = item.protein, let carbs = item.carbs, let fat = item.fat {
                                    MacrosCaptionLine(protein: protein, carbs: carbs, fat: fat)
                                        .padding(.top, 4)
                                }
                                
                                if let assumptions = item.assumptions, !assumptions.isEmpty {
                                    Text("Assumptions: \(assumptions)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if index < response.items.count - 1 {
                                    Divider()
                                        .padding(.top, 8)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                } else {
                    Text("Unable to load meal details")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            MealEditView(meal: meal)
        }
        .alert("Update Required", isPresented: $showUpdateRequiredAlert) {
            Button("Update Now") {
                if let appStoreURL = appConfigService.getAppStoreURL() {
                    UIApplication.shared.open(appStoreURL)
                }
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text(appConfigService.appConfig.updateMessage ?? "A new version of LogCal is available. Please update to continue.")
        }
        .onAppear {
            AnalyticsService.trackMealDetailViewed()
        }
    }

    @MainActor
    private func runQuickRefine() async {
        quickEditError = nil
        await appConfigService.fetchConfig()
        if !appConfigService.isAppVersionValid() {
            print("DEBUG: [MealDetailView] quick refine blocked — app update required")
            showUpdateRequiredAlert = true
            return
        }
        guard let openAIService = try? OpenAIService() else {
            quickEditError = "Could not start correction. Check your setup."
            print("DEBUG: [MealDetailView] OpenAIService init failed")
            return
        }
        isRefiningQuickEdit = true
        defer { isRefiningQuickEdit = false }
        do {
            _ = try await MealQuickRefine.apply(
                entry: meal,
                correctionPrompt: quickEditPrompt,
                modelContext: modelContext,
                openAIService: openAIService,
                cloudSyncService: cloudSyncService
            )
            quickEditPrompt = ""
            print("DEBUG: [MealDetailView] quick refine success")
        } catch {
            quickEditError = (error as? AppError)?.errorDescription ?? error.localizedDescription
            print("DEBUG: [MealDetailView] quick refine error: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        MealDetailView(meal: MealEntry(
            foodText: "2 rotis with dal",
            mealType: "lunch",
            totalCalories: 450,
            rawResponseJson: "{}"
        ))
    }
}

