//
//  NotificationsSettingsView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData

struct NotificationsSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    private let notificationService = NotificationService.shared
    private let firestoreService = FirestoreService()
    
    @AppStorage("mealRemindersEnabled") private var mealRemindersEnabled: Bool = true
    @State private var isLoading = false
    @State private var showPermissionAlert = false
    
    // Time pickers (using Date for DatePicker, but we only care about time)
    @State private var breakfastTime: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var lunchTime: Date = {
        var components = DateComponents()
        components.hour = 13
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var dinnerTime: Date = {
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.extraLarge) {
                    // Header
                    HStack {
                        Text("Notifications")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.top, Constants.Spacing.regular)
                    
                    // Meal Reminders Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                        Text("Meal Reminders")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        
                        HStack(spacing: Constants.Spacing.regular) {
                            // Icon
                            Image(systemName: "bell.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Theme.accentBlue)
                                .frame(width: 24, height: 24)
                            
                            // Title
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Meal Reminders")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(.primary)
                                
                                Text("Get reminded to log your meals at breakfast, lunch, and dinner time")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryText)
                            }
                            
                            Spacer()
                            
                            // Toggle
                            Toggle("", isOn: $mealRemindersEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: Theme.accentBlue))
                                .onChange(of: mealRemindersEnabled) { oldValue, newValue in
                                    handleToggleChange(newValue)
                                }
                        }
                        .padding(Constants.Spacing.large)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                        )
                        .cornerRadius(Constants.Sizes.largeCornerRadius)
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                        
                        // Time pickers (shown when reminders are enabled)
                        if mealRemindersEnabled {
                            VStack(spacing: Constants.Spacing.regular) {
                                // Breakfast time
                                HStack {
                                    Image(systemName: "sunrise.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.accentBlue)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Breakfast")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    DatePicker("", selection: $breakfastTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: breakfastTime) { oldValue, newValue in
                                            saveCustomTimes()
                                        }
                                }
                                .padding(Constants.Spacing.large)
                                .background(Theme.cardBackground(colorScheme: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                                )
                                .cornerRadius(Constants.Sizes.largeCornerRadius)
                                
                                // Lunch time
                                HStack {
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.accentBlue)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Lunch")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    DatePicker("", selection: $lunchTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: lunchTime) { oldValue, newValue in
                                            saveCustomTimes()
                                        }
                                }
                                .padding(Constants.Spacing.large)
                                .background(Theme.cardBackground(colorScheme: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                                )
                                .cornerRadius(Constants.Sizes.largeCornerRadius)
                                
                                // Dinner time
                                HStack {
                                    Image(systemName: "moon.stars.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.accentBlue)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Dinner")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    DatePicker("", selection: $dinnerTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .onChange(of: dinnerTime) { oldValue, newValue in
                                            saveCustomTimes()
                                        }
                                }
                                .padding(Constants.Spacing.large)
                                .background(Theme.cardBackground(colorScheme: colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Constants.Sizes.largeCornerRadius)
                                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                                )
                                .cornerRadius(Constants.Sizes.largeCornerRadius)
                            }
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                            .padding(.top, Constants.Spacing.small)
                        }
                    }
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.secondaryText)
                            Text("You won't receive a reminder if you've already logged that meal or logged anything in the last 30 minutes.")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.secondaryText)
                        }
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    }
                    .padding(.top, Constants.Spacing.regular)
                }
                .padding(.bottom, Constants.Spacing.extraLarge)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Theme.backgroundColor(colorScheme: colorScheme))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Notification Permission Required", isPresented: $showPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to receive meal reminders.")
            }
            .onAppear {
                AnalyticsService.trackViewOpened(viewName: "Notifications Settings")
                loadNotificationPreferences()
            }
        }
    }
    
    private func handleToggleChange(_ enabled: Bool) {
        print("DEBUG: [NotificationsSettings] Meal reminders toggled: \(enabled)")
        isLoading = true
        
        Task {
            // Get current times
            let calendar = Calendar.current
            let breakfastComponents = calendar.dateComponents([.hour, .minute], from: breakfastTime)
            let lunchComponents = calendar.dateComponents([.hour, .minute], from: lunchTime)
            let dinnerComponents = calendar.dateComponents([.hour, .minute], from: dinnerTime)
            
            let breakfast = (hour: breakfastComponents.hour ?? 8, minute: breakfastComponents.minute ?? 0)
            let lunch = (hour: lunchComponents.hour ?? 13, minute: lunchComponents.minute ?? 0)
            let dinner = (hour: dinnerComponents.hour ?? 20, minute: dinnerComponents.minute ?? 0)
            
            // Save to Firestore
            do {
                try await firestoreService.saveNotificationPreferences(
                    mealRemindersEnabled: enabled,
                    breakfastTime: breakfast,
                    lunchTime: lunch,
                    dinnerTime: dinner
                )
                print("DEBUG: [NotificationsSettings] Saved preference to Firestore")
            } catch {
                print("DEBUG: [NotificationsSettings] Error saving to Firestore: \(error)")
            }
            
            // Schedule or cancel notifications
            if enabled {
                // Check permission first
                let isAuthorized = await notificationService.checkAuthorizationStatus()
                if !isAuthorized {
                    let granted = await notificationService.requestAuthorization()
                    if !granted {
                        await MainActor.run {
                            mealRemindersEnabled = false
                            showPermissionAlert = true
                            isLoading = false
                        }
                        return
                    }
                }
                
                // Schedule notifications with custom times
                await notificationService.scheduleMealReminders(
                    modelContext: modelContext,
                    breakfastTime: breakfast,
                    lunchTime: lunch,
                    dinnerTime: dinner
                )
                AnalyticsService.trackNotificationPreferenceChanged(mealRemindersEnabled: true)
            } else {
                // Cancel notifications
                notificationService.cancelAllMealReminders()
                AnalyticsService.trackNotificationPreferenceChanged(mealRemindersEnabled: false)
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func saveCustomTimes() {
        Task {
            let calendar = Calendar.current
            let breakfastComponents = calendar.dateComponents([.hour, .minute], from: breakfastTime)
            let lunchComponents = calendar.dateComponents([.hour, .minute], from: lunchTime)
            let dinnerComponents = calendar.dateComponents([.hour, .minute], from: dinnerTime)
            
            let breakfast = (hour: breakfastComponents.hour ?? 8, minute: breakfastComponents.minute ?? 0)
            let lunch = (hour: lunchComponents.hour ?? 13, minute: lunchComponents.minute ?? 0)
            let dinner = (hour: dinnerComponents.hour ?? 20, minute: dinnerComponents.minute ?? 0)
            
            // Save to Firestore
            do {
                try await firestoreService.saveNotificationPreferences(
                    mealRemindersEnabled: mealRemindersEnabled,
                    breakfastTime: breakfast,
                    lunchTime: lunch,
                    dinnerTime: dinner
                )
                print("DEBUG: [NotificationsSettings] Saved custom times to Firestore")
            } catch {
                print("DEBUG: [NotificationsSettings] Error saving custom times to Firestore: \(error)")
            }
            
            // Reschedule notifications if enabled
            if mealRemindersEnabled {
                await notificationService.scheduleMealReminders(
                    modelContext: modelContext,
                    breakfastTime: breakfast,
                    lunchTime: lunch,
                    dinnerTime: dinner
                )
            }
        }
    }
    
    private func loadNotificationPreferences() {
        Task {
            do {
                if let prefs = try await firestoreService.fetchNotificationPreferences() {
                    await MainActor.run {
                        mealRemindersEnabled = prefs.mealRemindersEnabled
                        
                        // Load custom times if available
                        if let breakfast = prefs.breakfastTime {
                            var components = DateComponents()
                            components.hour = breakfast.hour
                            components.minute = breakfast.minute
                            breakfastTime = Calendar.current.date(from: components) ?? breakfastTime
                        }
                        if let lunch = prefs.lunchTime {
                            var components = DateComponents()
                            components.hour = lunch.hour
                            components.minute = lunch.minute
                            lunchTime = Calendar.current.date(from: components) ?? lunchTime
                        }
                        if let dinner = prefs.dinnerTime {
                            var components = DateComponents()
                            components.hour = dinner.hour
                            components.minute = dinner.minute
                            dinnerTime = Calendar.current.date(from: components) ?? dinnerTime
                        }
                        
                        print("DEBUG: [NotificationsSettings] Loaded preferences from Firestore: enabled=\(prefs.mealRemindersEnabled)")
                    }
                } else {
                    print("DEBUG: [NotificationsSettings] No preference found in Firestore, using defaults")
                }
            } catch {
                print("DEBUG: [NotificationsSettings] Error loading preference from Firestore: \(error)")
            }
        }
    }
}

#Preview {
    NotificationsSettingsView()
        .modelContainer(for: MealEntry.self)
}
