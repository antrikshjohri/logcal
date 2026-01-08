//
//  MealEditView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData

struct MealEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var cloudSyncService: CloudSyncService
    
    let meal: MealEntry
    @State private var editedDate: Date
    @State private var editedMealType: String
    @State private var editedCalories: Double
    @State private var isEditingCalories: Bool = false
    @State private var showCalorieEditConfirmation: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showDatePicker: Bool = false
    @State private var caloriesManuallyOverridden: Bool = false
    @State private var originalResponseJson: String?
    @State private var modifiedResponse: MealLogResponse?
    @FocusState private var isCaloriesFieldFocused: Bool
    
    // Meal type options
    private let mealTypes = ["breakfast", "lunch", "dinner", "snack"]
    
    init(meal: MealEntry) {
        self.meal = meal
        _editedDate = State(initialValue: meal.timestamp)
        _editedMealType = State(initialValue: meal.mealType)
        _editedCalories = State(initialValue: meal.totalCalories)
        
        // Check if calories were manually overridden
        // This would be stored in a separate field, but for now we'll infer from response
        if let response = meal.response {
            let totalFromItems = response.items.reduce(0) { $0 + $1.calories }
            // If total calories don't match sum of items, it was manually overridden
            _caloriesManuallyOverridden = State(initialValue: abs(totalFromItems - meal.totalCalories) > 0.01)
        }
        _originalResponseJson = State(initialValue: meal.rawResponseJson)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.large) {
                // Date and Meal Type in same row
                HStack(spacing: Constants.Spacing.regular) {
                    // Date Field
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Date")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack {
                                Text(DateFormatterCache.formatDate(editedDate))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(Constants.Colors.primaryBlue)
                            }
                            .padding()
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(Constants.Sizes.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Meal Type Field
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Meal Type")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Meal Type", selection: $editedMealType) {
                            ForEach(mealTypes, id: \.self) { type in
                                Text(type.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .frame(height: 44)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(Constants.Sizes.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Time Field (Read-only)
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    Text("Time")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(meal.timestamp, style: .time)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Theme.cardBackground(colorScheme: colorScheme).opacity(0.5))
                    .cornerRadius(Constants.Sizes.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                            .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                    )
                }
                
                // What you ate Field (Read-only)
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    Text("What you ate")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(meal.foodText)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Theme.cardBackground(colorScheme: colorScheme).opacity(0.5))
                    .cornerRadius(Constants.Sizes.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                            .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                    )
                }
                
                // Total Calories Field (Editable)
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    Text("Total Calories")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: Constants.Spacing.regular) {
                        HStack {
                            ZStack(alignment: .leading) {
                                // Always render TextField but hide when not editing
                                TextField("Calories", value: $editedCalories, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Constants.Colors.primaryBlue)
                                    .focused($isCaloriesFieldFocused)
                                    .opacity(isEditingCalories ? 1 : 0)
                                    .allowsHitTesting(isEditingCalories)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.clear)
                                
                                // Show text when not editing
                                if !isEditingCalories {
                                    HStack {
                                        Text("\(Int(editedCalories)) cal")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(Constants.Colors.primaryBlue)
                                        Spacer()
                                    }
                                    .allowsHitTesting(false)
                                }
                            }
                            
                            if !isEditingCalories {
                                Button(action: {
                                    isEditingCalories = true
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(Constants.Colors.primaryBlue)
                                }
                            }
                        }
                        .padding()
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(Constants.Sizes.cornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                        )
                        
                        // Save and Cancel buttons below input field
                        if isEditingCalories {
                            HStack(spacing: Constants.Spacing.regular) {
                                Button("Cancel") {
                                    cancelCalorieEdit()
                                }
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Theme.cardBackground(colorScheme: colorScheme))
                                .cornerRadius(Constants.Sizes.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                                )
                                
                                Button("Save") {
                                    saveCalorieEdit()
                                }
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Constants.Colors.primaryBlue)
                                .cornerRadius(Constants.Sizes.cornerRadius)
                            }
                        }
                    }
                }
                .onChange(of: isEditingCalories) { oldValue, newValue in
                    if !newValue {
                        // When editing ends, remove focus
                        isCaloriesFieldFocused = false
                    }
                }
                
                // Manual Override Notice
                if caloriesManuallyOverridden {
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Calories manually overridden")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Reset to default") {
                                resetToDefault()
                            }
                            .font(.subheadline)
                            .foregroundColor(Constants.Colors.primaryBlue)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(Constants.Sizes.cornerRadius)
                    }
                }
                
                // Items Breakdown
                if let response = modifiedResponse ?? meal.response, !caloriesManuallyOverridden {
                    VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                        Text("Items Breakdown")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
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
                                        .foregroundColor(Constants.Colors.primaryBlue)
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
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(Constants.Sizes.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                        }
                    }
                }
                
                // Delete Meal Button
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Text("Delete Meal")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                .padding(.top, Constants.Spacing.extraLarge)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    saveChanges()
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    VStack {
                        DatePicker(
                            "Select Date",
                            selection: $editedDate,
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
                                showDatePicker = false
                            }
                        }
                    }
                }
            }
        .alert("Remove Items Breakdown?", isPresented: $showCalorieEditConfirmation) {
                Button("Cancel", role: .cancel) {
                    cancelCalorieEdit()
                }
                Button("Yes", role: .destructive) {
                    confirmCalorieEdit()
                }
        } message: {
            Text("Editing calories will remove the items breakdown. You can reset to default later.")
        }
        .alert("Delete Meal", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteMeal()
            }
        } message: {
            Text("Are you sure you want to delete this meal? This action cannot be undone.")
        }
        .onChange(of: isEditingCalories) { oldValue, newValue in
            if newValue && !oldValue {
                // Focus the text field when editing starts to open keyboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isCaloriesFieldFocused = true
                }
            }
        }
    }
    
    private func saveCalorieEdit() {
        guard editedCalories > 0 else {
            // Show error - calories must be > 0
            isEditingCalories = false
            return
        }
        
        if let response = meal.response {
            if response.items.count == 1 {
                // Single item - update that item's calories
                updateSingleItemCalories(newCalories: editedCalories)
            } else {
                // Multiple items - show confirmation
                showCalorieEditConfirmation = true
                return
            }
        } else {
            // No response - just update total
            isEditingCalories = false
        }
    }
    
    private func updateSingleItemCalories(newCalories: Double) {
        guard let response = meal.response, response.items.count == 1 else { return }
        
        let originalItem = response.items[0]
        
        // Create updated item with new calories
        let updatedItem = MealItem(
            name: originalItem.name,
            quantity: originalItem.quantity,
            calories: newCalories,
            assumptions: originalItem.assumptions,
            confidence: originalItem.confidence
        )
        
        // Create updated response
        let updatedResponse = MealLogResponse(
            mealType: response.mealType,
            totalCalories: newCalories,
            items: [updatedItem],
            needsClarification: response.needsClarification,
            clarifyingQuestion: response.clarifyingQuestion
        )
        
        modifiedResponse = updatedResponse
        isEditingCalories = false
    }
    
    private func confirmCalorieEdit() {
        // Mark as manually overridden - this removes items breakdown
        caloriesManuallyOverridden = true
        modifiedResponse = nil
        isEditingCalories = false
    }
    
    private func cancelCalorieEdit() {
        editedCalories = meal.totalCalories
        isEditingCalories = false
        showCalorieEditConfirmation = false
    }
    
    private func resetToDefault() {
        // Restore original response
        caloriesManuallyOverridden = false
        modifiedResponse = nil
        
        if let originalJson = originalResponseJson,
           let data = originalJson.data(using: .utf8),
           let response = try? JSONDecoder().decode(MealLogResponse.self, from: data) {
            editedCalories = response.totalCalories
            modifiedResponse = response
        } else if let response = meal.response {
            editedCalories = response.totalCalories
            modifiedResponse = response
        } else {
            editedCalories = meal.totalCalories
        }
    }
    
    private func saveChanges() {
        // Update meal with edited values
        meal.timestamp = editedDate
        meal.mealType = editedMealType
        meal.totalCalories = editedCalories
        
        // Update the response JSON if modified
        if let modified = modifiedResponse {
            // Encode the modified response
            if let jsonData = try? JSONEncoder().encode(modified),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                meal.rawResponseJson = jsonString
            }
        } else if caloriesManuallyOverridden {
            // If manually overridden with multiple items, we need to create a minimal response
            // For now, keep the original response but the UI won't show items breakdown
            // The calories mismatch will indicate manual override
        }
        
        do {
            try modelContext.save()
            
            // Sync to cloud
            Task {
                await cloudSyncService.syncMealToCloud(meal)
            }
            
            // Track analytics
            AnalyticsService.trackMealEdited()
            
            dismiss()
        } catch {
            print("DEBUG: Error saving meal: \(error)")
        }
    }
    
    private func deleteMeal() {
        // Track analytics
        AnalyticsService.trackMealDeleted()
        
        // Delete from cloud
        Task {
            await cloudSyncService.deleteMealFromCloud(meal)
        }
        
        modelContext.delete(meal)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("DEBUG: Error deleting meal: \(error)")
        }
    }
    
    // Helper function to find TextField in view hierarchy
    private func findTextField(in view: UIView) -> UITextField? {
        if let textField = view as? UITextField {
            return textField
        }
        for subview in view.subviews {
            if let textField = findTextField(in: subview) {
                return textField
            }
        }
        return nil
    }
}

// UIViewRepresentable wrapper for TextField that allows direct UIKit access
struct FocusableTextField: UIViewRepresentable {
    @Binding var value: Double
    @Binding var isFocused: Bool
    let placeholder: String
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .decimalPad
        textField.font = .systemFont(ofSize: 24, weight: .bold)
        textField.textColor = UIColor.systemBlue
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        let stringValue = value == 0 ? "" : "\(Int(value))"
        if uiView.text != stringValue {
            uiView.text = stringValue
        }
        
        // Handle focus
        if isFocused && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: FocusableTextField
        
        init(_ parent: FocusableTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            if let text = textField.text, let doubleValue = Double(text) {
                parent.value = doubleValue
            } else if textField.text?.isEmpty == true {
                parent.value = 0
            }
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
        }
    }
}

#Preview {
    NavigationView {
        MealEditView(meal: MealEntry(
            foodText: "Apple",
            mealType: "snack",
            totalCalories: 95,
            rawResponseJson: "{}"
        ))
    }
    .modelContainer(for: MealEntry.self)
}

