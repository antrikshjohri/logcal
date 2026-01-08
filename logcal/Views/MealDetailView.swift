//
//  MealDetailView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct MealDetailView: View {
    let meal: MealEntry
    @State private var showEditSheet: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(meal.foodText)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Show image indicator if image was used
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
                }
                .padding()
                
                Divider()
                
                // Total calories
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Calories")
                        .font(.headline)
                    Text("\(Int(meal.totalCalories))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)
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
        .onAppear {
            AnalyticsService.trackMealDetailViewed()
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

