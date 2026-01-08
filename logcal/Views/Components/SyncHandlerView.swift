//
//  SyncHandlerView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData
import FirebaseAuth

struct SyncHandlerView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var cloudSyncService: CloudSyncService
    @ObservedObject var authViewModel: AuthViewModel
    @AppStorage("dailyGoal") private var dailyGoal: Double = 2000
    @AppStorage("mealRemindersEnabled") private var mealRemindersEnabled: Bool = true
    @State private var hasSyncedOnLaunch = false
    
    var body: some View {
        Color.clear
            .task {
                // Wait a bit to ensure modelContext is ready and SwiftData has loaded persisted data
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Handle app launch based on auth state
                if let user = Auth.auth().currentUser {
                    if user.isAnonymous {
                        print("DEBUG: Anonymous user on launch, initializing anonymous session...")
                        await cloudSyncService.initializeAnonymousSession(modelContext: modelContext)
                        hasSyncedOnLaunch = true
                    } else {
                        // Check if we already have local data before syncing
                        let descriptor = FetchDescriptor<MealEntry>()
                        if let localMeals = try? modelContext.fetch(descriptor), !localMeals.isEmpty {
                            print("DEBUG: User is signed in on launch with existing local data (\(localMeals.count) meals), skipping meal sync but fetching daily goal")
                            // Still fetch daily goal even if we have local meals
                            await fetchDailyGoalFromCloud()
                            // Schedule notifications if enabled
                            if mealRemindersEnabled {
                                print("DEBUG: [SyncHandlerView] mealRemindersEnabled=true, scheduling notifications...")
                                await NotificationService.shared.scheduleMealReminders(modelContext: modelContext)
                            } else {
                                print("DEBUG: [SyncHandlerView] mealRemindersEnabled=false, skipping notification scheduling")
                            }
                            hasSyncedOnLaunch = true
                        } else {
                            print("DEBUG: User is signed in on launch with no local data, syncing from cloud...")
                            await cloudSyncService.syncFromCloud(modelContext: modelContext)
                            // Fetch daily goal from cloud
                            await fetchDailyGoalFromCloud()
                            hasSyncedOnLaunch = true
                        }
                    }
                }
            }
            .onChange(of: authViewModel.currentUser) { oldValue, newValue in
                // #region agent log
                DebugLogger.log(location: "SyncHandlerView.swift:37", message: "onChange triggered for currentUser", data: ["oldUserId": oldValue?.uid ?? "nil", "newUserId": newValue?.uid ?? "nil", "oldIsAnonymous": oldValue?.isAnonymous ?? false, "newIsAnonymous": newValue?.isAnonymous ?? false], hypothesisId: "A")
                // #endregion
                // Note: We don't clear data on sign-out here because:
                // 1. The view might be removed from hierarchy, making modelContext invalid
                // 2. Data will be cleared automatically when a new user signs in (handled in syncFromCloud)
                // 3. If the same user signs in again, we don't want to clear their data
                
                // Handle switching to anonymous
                if let newUser = newValue, newUser.isAnonymous {
                    let wasAuthenticated = oldValue != nil && !oldValue!.isAnonymous
                    
                    if wasAuthenticated {
                        // Switching from authenticated to anonymous - clear authenticated data
                        print("DEBUG: Switching from authenticated to anonymous, clearing authenticated data...")
                        Task {
                            await cloudSyncService.initializeAnonymousSession(modelContext: modelContext)
                        }
                    } else if oldValue == nil {
                        // First time anonymous sign-in
                        print("DEBUG: Initializing anonymous session...")
                        Task {
                            await cloudSyncService.initializeAnonymousSession(modelContext: modelContext)
                        }
                    }
                }
                // Handle sync when authenticated user signs in or switches accounts
                else if let newUser = newValue, !newUser.isAnonymous {
                    let wasAnonymous = oldValue?.isAnonymous == true
                    let wasNil = oldValue == nil
                    let oldUserId = oldValue?.uid
                    let newUserId = newUser.uid
                    let userChanged = oldUserId != nil && !oldValue!.isAnonymous && oldUserId != newUserId
                    
                    if wasAnonymous || wasNil || userChanged {
                        // #region agent log
                        DebugLogger.log(location: "SyncHandlerView.swift:72", message: "Starting sync after sign-in in onChange", data: ["wasAnonymous": wasAnonymous, "wasNil": wasNil, "userChanged": userChanged, "newUserId": newUser.uid], hypothesisId: "A")
                        // #endregion
                        // User just signed in (not anonymous) or switched accounts - sync data
                        Task {
                            // Wait a bit to ensure modelContext is ready
                            // Use a shorter delay since we're already in the onChange handler
                            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                            
                            if userChanged {
                                print("DEBUG: User switched accounts, syncing new user's data...")
                                // For account switch, syncFromCloud will clear old data automatically
                                await cloudSyncService.syncFromCloud(modelContext: modelContext)
                                // Fetch daily goal from cloud
                                await fetchDailyGoalFromCloud()
                                // Schedule notifications if enabled
                                if mealRemindersEnabled {
                                    await NotificationService.shared.scheduleMealReminders(modelContext: modelContext)
                                }
                            } else if wasAnonymous {
                                print("DEBUG: Switching from anonymous to authenticated, migrating anonymous data...")
                                // First migrate anonymous local data to cloud
                                await cloudSyncService.migrateLocalToCloud(modelContext: modelContext)
                                // Then fetch any cloud data for authenticated user
                                await cloudSyncService.syncFromCloud(modelContext: modelContext)
                                // Fetch daily goal from cloud
                                await fetchDailyGoalFromCloud()
                                // Schedule notifications if enabled
                                if mealRemindersEnabled {
                                    await NotificationService.shared.scheduleMealReminders(modelContext: modelContext)
                                }
                            } else {
                                print("DEBUG: User signed in, migrating and syncing data...")
                                // First migrate local data to cloud (only if there are local meals)
                                await cloudSyncService.migrateLocalToCloud(modelContext: modelContext)
                                // Then fetch any cloud data
                                await cloudSyncService.syncFromCloud(modelContext: modelContext)
                                // Fetch daily goal from cloud
                                await fetchDailyGoalFromCloud()
                                // Schedule notifications if enabled
                                if mealRemindersEnabled {
                                    await NotificationService.shared.scheduleMealReminders(modelContext: modelContext)
                                }
                            }
                            
                            // #region agent log
                            DebugLogger.log(location: "SyncHandlerView.swift:onChange", message: "Sync completed in onChange", data: ["newUserId": newUser.uid], hypothesisId: "A")
                            // #endregion
                        }
                    }
                }
            }
            .onAppear {
                // #region agent log
                DebugLogger.log(location: "SyncHandlerView.swift:onAppear", message: "SyncHandlerView appeared", data: ["hasSyncedOnLaunch": hasSyncedOnLaunch, "currentUserId": Auth.auth().currentUser?.uid ?? "nil"], hypothesisId: "A")
                // #endregion
                // Also try to sync when view appears (as a fallback)
                // This is important when the view appears after sign-in
                // But only if we haven't synced yet and don't have local data
                Task { @MainActor in
                    // Wait a moment to ensure modelContext is fully ready and SwiftData has loaded persisted data
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    
                    if let user = Auth.auth().currentUser {
                        if user.isAnonymous {
                            if !hasSyncedOnLaunch {
                                print("DEBUG: SyncHandlerView appeared with anonymous user, initializing...")
                                await cloudSyncService.initializeAnonymousSession(modelContext: modelContext)
                                hasSyncedOnLaunch = true
                            }
                        } else {
                            // Check if we already have local data before syncing
                            let descriptor = FetchDescriptor<MealEntry>()
                            if let localMeals = try? modelContext.fetch(descriptor), !localMeals.isEmpty {
                                print("DEBUG: SyncHandlerView appeared with authenticated user and existing local data (\(localMeals.count) meals), skipping sync")
                                // Schedule notifications if enabled
                                if mealRemindersEnabled {
                                    await NotificationService.shared.scheduleMealReminders(modelContext: modelContext)
                                }
                                hasSyncedOnLaunch = true
                            } else if !hasSyncedOnLaunch {
                                // Only sync if we haven't synced yet and have no local data
                                // This ensures data loads when TabView appears after sign-in
                                print("DEBUG: SyncHandlerView appeared with authenticated user and no local data, syncing from cloud...")
                                // #region agent log
                                DebugLogger.log(location: "SyncHandlerView.swift:onAppear", message: "Starting sync in onAppear", data: ["userId": user.uid], hypothesisId: "A")
                                // #endregion
                                await cloudSyncService.syncFromCloud(modelContext: modelContext)
                                // Fetch daily goal from cloud
                                await fetchDailyGoalFromCloud()
                                // Schedule notifications if enabled
                                if mealRemindersEnabled {
                                    await NotificationService.shared.scheduleMealReminders(modelContext: modelContext)
                                }
                                // #region agent log
                                DebugLogger.log(location: "SyncHandlerView.swift:onAppear", message: "Sync completed in onAppear", data: ["userId": user.uid], hypothesisId: "A")
                                // #endregion
                                hasSyncedOnLaunch = true
                            }
                        }
                    }
                }
            }
    }
    
    /// Fetch daily goal from cloud and update AppStorage
    private func fetchDailyGoalFromCloud() async {
        print("DEBUG: fetchDailyGoalFromCloud called, current local goal: \(dailyGoal)")
        if let cloudGoal = await cloudSyncService.fetchDailyGoalFromCloud() {
            print("DEBUG: Fetched goal from cloud: \(cloudGoal), current local: \(dailyGoal)")
            // Always update if we got a value from cloud (even if same, to ensure sync)
            // Only skip if cloudGoal is 0 or invalid
            if cloudGoal > 0 {
                print("DEBUG: Updating daily goal from cloud: \(cloudGoal) (was \(dailyGoal))")
                dailyGoal = cloudGoal
                print("DEBUG: Daily goal updated to: \(dailyGoal)")
            } else {
                print("DEBUG: Cloud goal is invalid (\(cloudGoal)), not updating")
            }
        } else {
            print("DEBUG: No goal fetched from cloud (returned nil)")
        }
    }
}

