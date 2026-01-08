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
                    }
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.secondaryText)
                            Text("Notifications are sent at 8 AM (breakfast), 1 PM (lunch), and 8 PM (dinner). You won't receive a reminder if you've already logged that meal or logged anything in the last 2 hours.")
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
            // Save to Firestore
            do {
                try await firestoreService.saveNotificationPreferences(mealRemindersEnabled: enabled)
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
                
                // Schedule notifications
                await notificationService.scheduleMealReminders(modelContext: modelContext)
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
    
    private func loadNotificationPreferences() {
        Task {
            do {
                if let preference = try await firestoreService.fetchNotificationPreferences() {
                    await MainActor.run {
                        mealRemindersEnabled = preference
                        print("DEBUG: [NotificationsSettings] Loaded preference from Firestore: \(preference)")
                    }
                } else {
                    print("DEBUG: [NotificationsSettings] No preference found in Firestore, using default: \(mealRemindersEnabled)")
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
