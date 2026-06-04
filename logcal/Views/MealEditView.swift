//
//  MealEditView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData
import UIKit

struct MealEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var cloudSyncService: CloudSyncService
    @Query(sort: \SavedMeal.updatedAt, order: .reverse) private var savedMeals: [SavedMeal]
    
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
    @State private var didSaveToFavorites: Bool = false
    @State private var savedMealCreatedInSession: SavedMeal?
    @State private var savedMealPendingDeletion: SavedMeal?
    @State private var mealBeingSavedAndRenamed: SavedMeal?
    @State private var renameText = ""
    @State private var quickEditPrompt: String = ""
    @State private var showQuickEdit: Bool = false
    @State private var isQuickEditLoading: Bool = false
    @State private var quickEditErrorMessage: String?
    @State private var openAIService: OpenAIService?
    @State private var openAIServiceError: AppError?
    @FocusState private var isCaloriesFieldFocused: Bool
    
    // Meal type options
    private let mealTypes = ["breakfast", "lunch", "dinner", "snack"]

    private var matchingSavedMeal: SavedMeal? {
        savedMeals.first { SavedMealMatcher.matches($0, meal: meal) }
    }

    private var currentSavedMeal: SavedMeal? {
        matchingSavedMeal ?? savedMealCreatedInSession
    }

    private var isSavedToFavorites: Bool {
        didSaveToFavorites || currentSavedMeal != nil
    }
    
    init(meal: MealEntry) {
        self.meal = meal
        _editedDate = State(initialValue: meal.timestamp)
        _editedMealType = State(initialValue: meal.mealType)
        _editedCalories = State(initialValue: meal.totalCalories)
        do {
            _openAIService = State(initialValue: try OpenAIService())
            _openAIServiceError = State(initialValue: nil)
        } catch {
            _openAIService = State(initialValue: nil)
            if let appError = error as? AppError {
                _openAIServiceError = State(initialValue: appError)
            } else {
                _openAIServiceError = State(initialValue: AppError.unknown(error))
            }
        }
        
        // Check if calories were manually overridden
        // This would be stored in a separate field, but for now we'll infer from response
        if let response = meal.response {
            let totalFromItems = response.items.reduce(0) { $0 + $1.calories }
            // If total calories don't match sum of items, it was manually overridden
            _caloriesManuallyOverridden = State(initialValue: abs(totalFromItems - meal.totalCalories) > 0.01)
        }
        _originalResponseJson = State(initialValue: meal.rawResponseJson)
        
        // #region agent log
        print("DEBUG: [MealEditView] init - protein: \(meal.protein as Any), carbs: \(meal.carbs as Any), fat: \(meal.fat as Any)")
        print("DEBUG: [MealEditView] init - response exists: \(meal.response != nil)")
        if let response = meal.response {
            print("DEBUG: [MealEditView] init - response.protein: \(response.protein as Any), response.carbs: \(response.carbs as Any), response.fat: \(response.fat as Any)")
        }
        // #endregion
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Clear spacer at top of ScrollView content to prevent it from starting hidden under the navigation bar
                Color.clear
                    .frame(height: 12)
                
                // Success Header / Title Card
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.primaryGreen)
                        .padding(.top, 8)
                    
                    Text("Meal Logged!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                }
                .frame(maxWidth: .infinity)
                
                // Estimated Calories Card (Interactive)
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 6) {
                        if isEditingCalories {
                            HStack(spacing: 4) {
                                TextField("Calories", value: $editedCalories, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 44, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.primaryGreen)
                                    .focused($isCaloriesFieldFocused)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 180)
                                
                                Text("cal")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            }
                        } else {
                            Text("\(Int(editedCalories)) cal")
                                .font(.system(size: 44, weight: .black, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        }
                        
                        Text("ESTIMATED CALORIES")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(Theme.cardBackground(colorScheme: colorScheme))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                    )
                    .shadow(color: Theme.shadowColor(colorScheme: colorScheme), radius: 6, x: 0, y: 3)
                    
                    if !isEditingCalories {
                        Button(action: {
                            isEditingCalories = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.primaryGreen)
                                .padding(8)
                                .background(Theme.softAccentBackground(colorScheme: colorScheme))
                                .clipShape(Circle())
                        }
                        .padding(12)
                    }
                }
                
                // Save and Cancel buttons below calorie input field in edit mode
                if isEditingCalories {
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            cancelCalorieEdit()
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                        )
                        
                        Button("Save") {
                            saveCalorieEdit()
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.primaryGreen)
                        .cornerRadius(22)
                    }
                    .transition(.opacity)
                }
                
                // Macros Row (uses modifiedResponse if present to remain reactive)
                if let macros = (modifiedResponse ?? meal.response)?.resolvedMealMacrosForDisplay() {
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.proteinColor)
                                .frame(width: 8, height: 8)
                            Text("\(Int(macros.protein))g Protein")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.proteinColor.opacity(0.12))
                        .cornerRadius(12)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.carbsColor)
                                .frame(width: 8, height: 8)
                            Text("\(Int(macros.carbs))g Carbs")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.carbsColor.opacity(0.12))
                        .cornerRadius(12)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.fatColor)
                                .frame(width: 8, height: 8)
                            Text("\(Int(macros.fat))g Fat")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.fatColor.opacity(0.12))
                        .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // Manual Override Notice
                if caloriesManuallyOverridden {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Calories manually overridden")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.orange)
                            Spacer()
                            Button("Reset") {
                                resetToDefault()
                            }
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryGreen)
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Details Card (Date, Meal Type, Time, Description/What you ate)
                VStack(spacing: 16) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            Text("Date")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        }
                        Spacer()
                        Button(action: {
                            showDatePicker = true
                        }) {
                            HStack(spacing: 6) {
                                Text(DateFormatterCache.formatDate(editedDate))
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.primaryGreen)
                                    .frame(width: 26, height: 26)
                                    .background(Theme.softAccentBackground(colorScheme: colorScheme))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    Divider()
                        .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                    
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            Text("Meal Type")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        }
                        Spacer()
                        
                        Picker("Meal Type", selection: $editedMealType) {
                            ForEach(mealTypes, id: \.self) { type in
                                Text(type.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .accentColor(Theme.primaryGreen)
                    }
                    
                    Divider()
                        .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                    
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            Text("Logged At")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        }
                        Spacer()
                        Text(meal.timestamp, style: .time)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    }
                    
                    Divider()
                        .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("What you ate")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showQuickEdit.toggle()
                                }
                            } label: {
                                Image(systemName: showQuickEdit ? "xmark" : "pencil")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.primaryGreen)
                                    .frame(width: 26, height: 26)
                                    .background(Theme.softAccentBackground(colorScheme: colorScheme))
                                    .clipShape(Circle())
                            }
                        }
                        
                        Text(meal.foodText)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Theme.insetBackground(colorScheme: colorScheme))
                            .cornerRadius(10)
                        
                        if showQuickEdit {
                            QuickEditMealSection(
                                prompt: $quickEditPrompt,
                                isLoading: isQuickEditLoading,
                                errorMessage: quickEditErrorMessage
                            ) {
                                Task {
                                    await quickRefineMeal()
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding(16)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                )
                .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.5), radius: 4, x: 0, y: 2)
                
                // Items Breakdown List Card
                if let response = modifiedResponse ?? meal.response, !caloriesManuallyOverridden {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Items Breakdown")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 16) {
                            ForEach(Array(response.items.enumerated()), id: \.offset) { index, item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.name)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                        Spacer()
                                        Text("\(Int(item.calories)) cal")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(Theme.primaryGreen)
                                    }
                                    
                                    Text("Quantity: \(item.quantity)")
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                    
                                    if let p = item.protein, let c = item.carbs, let f = item.fat {
                                        MacrosCaptionLine(protein: p, carbs: c, fat: f, font: .system(size: 12, design: .rounded))
                                            .padding(.top, 2)
                                    }
                                    
                                    if let assumptions = item.assumptions, !assumptions.isEmpty {
                                        Text("Assumptions: \(assumptions)")
                                            .font(.system(size: 11, design: .rounded))
                                            .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                                            .padding(.top, 2)
                                    }
                                }
                                
                                if index < response.items.count - 1 {
                                    Divider()
                                        .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                }
                            }
                        }
                        .padding(16)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                        )
                        .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                }
                
                // Favorites and Delete Row
                HStack(spacing: 12) {
                    Button(action: {
                        if let savedMeal = currentSavedMeal {
                            savedMealPendingDeletion = savedMeal
                        } else {
                            saveAsFavorite()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isSavedToFavorites ? "bookmark.fill" : "bookmark")
                            Text(isSavedToFavorites ? "Saved" : "Save Favourite")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.primaryGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.softAccentBackground(colorScheme: colorScheme))
                        .cornerRadius(25)
                    }

                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                            Text("Delete")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.dangerRed)
                        .cornerRadius(25)
                        .shadow(color: Theme.dangerRed.opacity(0.25), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.top, 16)
            }
            .padding(16)
        }
        .background(
            Theme.backgroundColor(colorScheme: colorScheme)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !isEditingCalories {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
        )
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: editedDate) { oldValue, newValue in
            autoSaveChanges()
        }
        .onChange(of: editedMealType) { oldValue, newValue in
            autoSaveChanges()
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "Select Date",
                        selection: $editedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(Theme.primaryGreen)
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
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryGreen)
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
        .alert("Delete Favourite Meal", isPresented: Binding(
            get: { savedMealPendingDeletion != nil },
            set: { if !$0 { savedMealPendingDeletion = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                savedMealPendingDeletion = nil
            }
            Button("Delete", role: .destructive) {
                deleteSavedMeal()
            }
        } message: {
            Text("Are you sure you want to delete this favourite meal? This action cannot be undone.")
        }
        .alert("Rename Favourite Meal", isPresented: Binding(
            get: { mealBeingSavedAndRenamed != nil },
            set: { if !$0 { mealBeingSavedAndRenamed = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {
                mealBeingSavedAndRenamed = nil
            }
            Button("Save") {
                if let savedMeal = mealBeingSavedAndRenamed {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        savedMeal.title = String(trimmed.prefix(140))
                        savedMeal.updatedAt = Date()
                        try? modelContext.save()
                        
                        Task {
                            await cloudSyncService.syncSavedMealsToCloud(modelContext: modelContext)
                        }
                    }
                }
                mealBeingSavedAndRenamed = nil
            }
        }
        .onChange(of: isEditingCalories) { oldValue, newValue in
            if newValue && !oldValue {
                // Focus the text field when editing starts to open keyboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isCaloriesFieldFocused = true
                }
            } else if oldValue && !newValue {
                autoSaveChanges()
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
            protein: originalItem.protein,
            carbs: originalItem.carbs,
            fat: originalItem.fat,
            assumptions: originalItem.assumptions,
            confidence: originalItem.confidence
        )
        
        // Create updated response
        let updatedResponse = MealLogResponse(
            mealType: response.mealType,
            totalCalories: newCalories,
            protein: response.protein,
            carbs: response.carbs,
            fat: response.fat,
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
        autoSaveChanges()
    }
    
    private func autoSaveChanges() {
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
        }
        
        // Update linked favorite if it exists
        updateLinkedFavoriteIfNeeded()
        
        do {
            try modelContext.save()
            
            // Sync to cloud
            Task {
                await cloudSyncService.syncMealToCloud(meal)
            }
            
            // Track analytics
            AnalyticsService.trackMealEdited()
        } catch {
            print("DEBUG: Error saving meal: \(error)")
        }
    }

    private func updateLinkedFavoriteIfNeeded() {
        if let linkedFavorite = savedMeals.first(where: { $0.sourceMealId == meal.id }) {
            linkedFavorite.foodText = meal.foodText
            linkedFavorite.mealType = meal.mealType
            linkedFavorite.totalCalories = meal.totalCalories
            linkedFavorite.rawResponseJson = meal.rawResponseJson
            linkedFavorite.updatedAt = Date()
            
            // Sync updated favorites to Firestore
            Task {
                await cloudSyncService.syncSavedMealsToCloud(modelContext: modelContext)
            }
        }
    }

    private func saveAsFavorite() {
        guard matchingSavedMeal == nil else {
            didSaveToFavorites = true
            return
        }

        let response: MealLogResponse
        if let modifiedResponse {
            response = modifiedResponse
        } else if let mealResponse = meal.response {
            response = mealResponse
        } else {
            response = MealLogResponse(
                mealType: editedMealType,
                totalCalories: editedCalories,
                protein: nil,
                carbs: nil,
                fat: nil,
                items: [],
                needsClarification: false,
                clarifyingQuestion: nil
            )
        }

        let rawJson: String
        if let jsonData = try? JSONEncoder().encode(response),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            rawJson = jsonString
        } else {
            rawJson = meal.rawResponseJson
        }

        let count = (try? modelContext.fetchCount(FetchDescriptor<SavedMeal>())) ?? 0
        let savedMeal = SavedMeal(
            title: SavedMealTitle.suggestedTitle(foodText: meal.foodText, response: response),
            foodText: meal.foodText,
            mealType: editedMealType,
            totalCalories: editedCalories,
            rawResponseJson: rawJson,
            sourceMealId: meal.id,
            displayOrder: count
        )

        modelContext.insert(savedMeal)
        do {
            meal.sourceSavedMealId = savedMeal.id
            try modelContext.save()
            didSaveToFavorites = true
            savedMealCreatedInSession = savedMeal
            renameText = savedMeal.title
            mealBeingSavedAndRenamed = savedMeal
            
            // Sync to cloud
            Task {
                await cloudSyncService.syncSavedMealsToCloud(modelContext: modelContext)
            }
        } catch {
            print("DEBUG: Error saving favorite meal: \(error)")
        }
    }

    private func deleteSavedMeal() {
        guard let savedMeal = savedMealPendingDeletion else { return }

        modelContext.delete(savedMeal)
        meal.sourceSavedMealId = nil
        do {
            try modelContext.save()
            if savedMealCreatedInSession?.id == savedMeal.id {
                savedMealCreatedInSession = nil
            }
            didSaveToFavorites = false
            savedMealPendingDeletion = nil
            
            // Sync to cloud
            Task {
                await cloudSyncService.syncSavedMealsToCloud(modelContext: modelContext)
            }
        } catch {
            print("DEBUG: Error deleting saved meal: \(error)")
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

    private func quickRefineMeal() async {
        let trimmed = quickEditPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let openAIService else {
            quickEditErrorMessage = openAIServiceError?.errorDescription ?? AppError.apiKeyNotFound.errorDescription
            return
        }

        isQuickEditLoading = true
        quickEditErrorMessage = nil
        defer { isQuickEditLoading = false }

        do {
            let refined = try await MealQuickRefine.apply(
                entry: meal,
                correctionPrompt: trimmed,
                modelContext: modelContext,
                openAIService: openAIService,
                cloudSyncService: cloudSyncService
            )
            editedMealType = refined.mealType
            editedCalories = refined.totalCalories
            modifiedResponse = refined
            caloriesManuallyOverridden = false
            updateLinkedFavoriteIfNeeded()
            try? modelContext.save()
            quickEditPrompt = ""
            withAnimation(.easeInOut(duration: 0.2)) {
                showQuickEdit = false
            }
        } catch {
            if let appError = error as? AppError {
                quickEditErrorMessage = appError.errorDescription
            } else {
                quickEditErrorMessage = error.localizedDescription
            }
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
    NavigationStack {
        MealEditView(meal: MealEntry(
            foodText: "Apple",
            mealType: "snack",
            totalCalories: 95,
            rawResponseJson: "{}"
        ))
    }
    .modelContainer(for: [MealEntry.self, SavedMeal.self])
}
