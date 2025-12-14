//
//  HomeView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var viewModel = LogViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Date and Meal Type in same line
                    HStack(spacing: 16) {
                        // Date picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.headline)
                            
                            Button(action: {
                                viewModel.showDatePicker = true
                            }) {
                                HStack {
                                    Text(viewModel.selectedDate, style: .date)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Meal type picker
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Meal Type")
                                    .font(.headline)
                                
                                Spacer()
                                
                                if viewModel.isMealTypeManuallySet {
                                    Text("(Manual)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("(Auto)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Picker("Meal Type", selection: $viewModel.selectedMealType) {
                                ForEach(MealType.allCases, id: \.self) { mealType in
                                    Text(mealType.rawValue.capitalized).tag(mealType)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: viewModel.selectedMealType) { oldValue, newValue in
                                viewModel.handleMealTypeChange(newValue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $viewModel.showDatePicker) {
                        NavigationView {
                            VStack {
                                DatePicker(
                                    "Select Date",
                                    selection: $viewModel.selectedDate,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                                .padding()
                                
                                Spacer()
                            }
                            .navigationTitle("Select Date")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        viewModel.showDatePicker = false
                                    }
                                }
                            }
                        }
                    }
                    
                    // Food text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What did you eat?")
                            .font(.headline)
                        
                        ZStack(alignment: .bottomTrailing) {
                            TextEditor(text: $viewModel.foodText)
                                .frame(minHeight: 100)
                                .padding(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            // Mic button
                            Button(action: {
                                viewModel.toggleSpeechRecognition()
                            }) {
                                Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                                    .font(.system(size: 20))
                                    .foregroundColor(viewModel.isListening ? .red : .blue)
                                    .padding(8)
                                    .background(viewModel.isListening ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 12)
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Log button
                    Button(action: {
                        Task {
                            await viewModel.logMeal()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Log Meal")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.foodText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    .padding(.horizontal)
                    
                    // Error banner
                    if let errorMessage = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Error")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    // Speech recognition error banner
                    if let speechError = viewModel.speechService.errorMessage {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Speech Recognition Error")
                                .font(.headline)
                            Text(speechError)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    // Result card
                    if let result = viewModel.latestResult {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Logged Successfully")
                                    .font(.headline)
                                Spacer()
                                Text(result.mealType.capitalized)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            
                            Text("Total Calories: \(Int(result.totalCalories))")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Divider()
                            
                            Text("Items:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(result.items.enumerated()), id: \.offset) { index, item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.name)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("\(Int(item.calories)) cal")
                                            .foregroundColor(.secondary)
                                    }
                                    Text("\(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let assumptions = item.assumptions, !assumptions.isEmpty {
                                        Text("Assumptions: \(assumptions)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text("Confidence: \(Int(item.confidence * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                                
                                if index < result.items.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Log Calories")
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: MealEntry.self)
}

