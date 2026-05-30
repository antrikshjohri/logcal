//
//  CloudSyncService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import SwiftData
import FirebaseAuth
import Combine

@MainActor
class CloudSyncService: ObservableObject {
    private let firestoreService = FirestoreService()
    @Published var isSyncing: Bool = false
    @Published var syncError: String?
    @Published var lastSyncTime: Date = Date() // Trigger view updates when sync completes
    private var currentUserId: String? // Track current authenticated user ID
    private var isAnonymousSession: Bool = false // Track if we're in anonymous mode
    private let userDefaults = UserDefaults.standard
    private let lastUserIdKey = "lastSyncedUserId" // Persist user ID to detect account switches
    
    /// Sync meal entries to Firestore (save new ones)
    func syncMealToCloud(_ entry: MealEntry) async {
        // Only sync if user is signed in (not anonymous)
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            print("DEBUG: User is anonymous or not signed in, skipping cloud sync")
            return
        }
        
        do {
            try await firestoreService.saveMealEntry(entry)
            print("DEBUG: Successfully synced meal to cloud: \(entry.id)")
        } catch {
            print("DEBUG: Error syncing meal to cloud: \(error)")
            syncError = "Failed to sync to cloud: \(error.localizedDescription)"
        }
    }
    
    /// Fetch all meals from Firestore and merge with local data
    func syncFromCloud(modelContext: ModelContext) async {
        // Only sync if user is signed in (not anonymous)
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            print("DEBUG: User is anonymous or not signed in, skipping cloud sync")
            // Clear authenticated session state
            currentUserId = nil
            return
        }
        
        let newUserId = user.uid
        
        // Check if we're switching from anonymous to authenticated
        if isAnonymousSession {
            print("DEBUG: Switching from anonymous to authenticated user, keeping local guest data to merge...")
            isAnonymousSession = false
        }
        
        // Get last synced user ID from UserDefaults (persists across sign outs)
        let lastSyncedUserId = userDefaults.string(forKey: lastUserIdKey)
        
        // Check if user has changed (different authenticated account signed in)
        if let previousUserId = currentUserId, previousUserId != newUserId {
            print("DEBUG: User changed from \(previousUserId) to \(newUserId), clearing local data first...")
            await clearLocalMeals(modelContext: modelContext)
        }
        // If currentUserId is nil but we have a different lastSyncedUserId, user switched accounts
        else if currentUserId == nil, let lastUserId = lastSyncedUserId, lastUserId != newUserId {
            print("DEBUG: Different user signing in (last: \(lastUserId), new: \(newUserId)), clearing local data first...")
            await clearLocalMeals(modelContext: modelContext)
        }
        // If currentUserId is nil and no lastSyncedUserId, but we have local data, clear it (fresh sign in with old data)
        else if currentUserId == nil, lastSyncedUserId == nil {
            let descriptor = FetchDescriptor<MealEntry>()
            if let localMeals = try? modelContext.fetch(descriptor), !localMeals.isEmpty {
                print("DEBUG: New user signing in with existing local data, clearing local data first...")
                await clearLocalMeals(modelContext: modelContext)
            }
        }
        
        // Update current user ID and session type
        currentUserId = newUserId
        isAnonymousSession = false
        
        // Persist user ID to UserDefaults to detect account switches after sign out
        userDefaults.set(newUserId, forKey: lastUserIdKey)
        
        isSyncing = true
        syncError = nil
        
        do {
            // #region agent log
            DebugLogger.log(location: "CloudSyncService.swift:80", message: "Starting fetch from Firestore", data: ["userId": newUserId], hypothesisId: "B")
            // #endregion
            // Fetch from Firestore
            let cloudMeals = try await firestoreService.fetchMealEntries()
            // #region agent log
            DebugLogger.log(location: "CloudSyncService.swift:82", message: "Fetched meals from Firestore", data: ["mealCount": cloudMeals.count], hypothesisId: "B")
            // #endregion
            print("DEBUG: Fetched \(cloudMeals.count) meals from cloud")
            
            // Get local meals
            let descriptor = FetchDescriptor<MealEntry>()
            let localMeals = try modelContext.fetch(descriptor)
            print("DEBUG: Found \(localMeals.count) local meals")
            
            // Create a set of local meal IDs for quick lookup
            let localMealIds = Set(localMeals.map { $0.id })
            
            // Add cloud meals that don't exist locally
            var addedCount = 0
            for cloudMeal in cloudMeals {
                if !localMealIds.contains(cloudMeal.id) {
                    modelContext.insert(cloudMeal)
                    addedCount += 1
                }
            }
            
            if addedCount > 0 {
                // #region agent log
                DebugLogger.log(location: "CloudSyncService.swift:102", message: "Saving meals to modelContext", data: ["addedCount": addedCount], hypothesisId: "B")
                // #endregion
                // Save the context
                try modelContext.save()
                // #region agent log
                DebugLogger.log(location: "CloudSyncService.swift:104", message: "Saved meals to modelContext", data: ["addedCount": addedCount], hypothesisId: "B")
                // #endregion
                print("DEBUG: Added \(addedCount) meals from cloud to local storage")
                
                // Verify the save worked by checking local meals again
                // Use a fresh fetch to ensure we're reading from the persisted store
                let verifyDescriptor = FetchDescriptor<MealEntry>()
                let verifyMeals = try modelContext.fetch(verifyDescriptor)
                print("DEBUG: After save, found \(verifyMeals.count) local meals")
                
                // #region agent log
                DebugLogger.log(location: "CloudSyncService.swift:122", message: "Verification after save", data: ["expectedCount": addedCount, "actualCount": verifyMeals.count], hypothesisId: "B")
                // #endregion
                
                // If verification shows 0 meals, there's a modelContext issue
                if verifyMeals.count == 0 && addedCount > 0 {
                    print("ERROR: modelContext.save() did not persist meals! This indicates a modelContext issue.")
                    // Try saving again
                    try modelContext.save()
                    let retryMeals = try modelContext.fetch(verifyDescriptor)
                    print("DEBUG: After retry save, found \(retryMeals.count) local meals")
                }
                
                // Small delay to ensure SwiftData propagates changes to @Query
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                
                // Update lastSyncTime to trigger onChange handlers in HistoryView
                // This will cause the view to check if refresh is needed
                lastSyncTime = Date()
                
                // Another small delay to ensure the view refresh happens
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            } else {
                print("DEBUG: No new meals to add from cloud")
            }
            
            isSyncing = false
            // Update lastSyncTime even if no meals were added to trigger any pending updates
            if addedCount == 0 {
                lastSyncTime = Date()
            }
        } catch {
            print("DEBUG: Error syncing from cloud: \(error)")
            syncError = "Failed to sync from cloud: \(error.localizedDescription)"
            isSyncing = false
        }
    }
    
    /// Migrate all local meals to cloud (for when user first signs in)
    func migrateLocalToCloud(modelContext: ModelContext) async {
        // Only migrate if user is signed in (not anonymous)
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            print("DEBUG: User is anonymous or not signed in, skipping migration")
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Get all local meals
            let descriptor = FetchDescriptor<MealEntry>()
            let localMeals = try modelContext.fetch(descriptor)
            print("DEBUG: Migrating \(localMeals.count) local meals to cloud")
            
            if !localMeals.isEmpty {
                try await firestoreService.syncLocalMealsToCloud(entries: localMeals)
                print("DEBUG: Successfully migrated \(localMeals.count) meals to cloud")
            }
            
            // Also migrate daily goal if it exists in UserDefaults
            // Note: We can't access @AppStorage here, so we'll read from UserDefaults directly
            let localDailyGoal = UserDefaults.standard.double(forKey: "dailyGoal")
            if localDailyGoal > 0 && localDailyGoal != 2000 { // Only migrate if it's been changed from default
                print("DEBUG: Migrating daily goal to cloud: \(localDailyGoal)")
                try await firestoreService.saveDailyGoal(localDailyGoal)
                print("DEBUG: Successfully migrated daily goal to cloud")
            }
            
            isSyncing = false
        } catch {
            print("DEBUG: Error migrating to cloud: \(error)")
            syncError = "Failed to migrate to cloud: \(error.localizedDescription)"
            isSyncing = false
        }
    }
    
    /// Delete meal from cloud
    func deleteMealFromCloud(_ entry: MealEntry) async {
        // Only delete from cloud if user is signed in (not anonymous)
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            print("DEBUG: User is anonymous or not signed in, skipping cloud delete")
            return
        }
        
        do {
            try await firestoreService.deleteMealEntry(entry)
            print("DEBUG: Successfully deleted meal from cloud: \(entry.id)")
        } catch {
            print("DEBUG: Error deleting meal from cloud: \(error)")
            syncError = "Failed to delete from cloud: \(error.localizedDescription)"
        }
    }
    
    /// Clear all local meals (used when user signs out or switches accounts)
    func clearLocalMeals(modelContext: ModelContext) async {
        print("DEBUG: Clearing all local meals...")
        
        let container = modelContext.container
        
        // CRITICAL: Perform deletion on a BACKGROUND THREAD using Task.detached.
        //
        // The root cause of the EXC_BREAKPOINT crash:
        // 1. We delete MealEntry objects and call save()
        // 2. save() internally posts an NSNotification via NSNotificationCenter
        // 3. NSNotificationCenter delivers notifications SYNCHRONOUSLY on the posting thread
        // 4. SwiftData_SwiftUI's @Query observer receives the notification on the main thread
        // 5. The observer tries to diff/process the deleted objects and crashes
        //
        // By using Task.detached with a separate ModelContext:
        // - The ModelContext is created and used entirely on a background thread
        // - save() posts the notification on the background thread
        // - SwiftData_SwiftUI's @Query observer (registered on main thread) processes
        //   the store change asynchronously, after the deletion is complete
        // - The @Query safely re-fetches from the (now empty) persistent store
        do {
            try await Task.detached(priority: .userInitiated) {
                let bgContext = ModelContext(container)
                bgContext.autosaveEnabled = false
                
                let descriptor = FetchDescriptor<MealEntry>()
                let localMeals = try bgContext.fetch(descriptor)
                guard !localMeals.isEmpty else {
                    print("DEBUG: No local meals to delete")
                    return
                }
                print("DEBUG: Found \(localMeals.count) local meals to delete (background thread)")
                for meal in localMeals {
                    bgContext.delete(meal)
                }
                try bgContext.save()
                print("DEBUG: Successfully cleared \(localMeals.count) local meals via background thread")
            }.value
        } catch {
            print("DEBUG: Error clearing local meals: \(error)")
        }
        
        // Allow time for the store change notification to propagate to the UI context's @Query
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Clear session state when clearing local data
        currentUserId = nil
        isAnonymousSession = false
        
        // Clear persisted user ID when clearing data
        userDefaults.removeObject(forKey: lastUserIdKey)
    }
    
    /// Initialize anonymous session (clear authenticated data when switching to anonymous)
    func initializeAnonymousSession(modelContext: ModelContext) async {
        print("DEBUG: Initializing anonymous session...")
        
        // Note: We no longer clear local meals here. They are safely cleared in logcalApp.swift
        // when the user signs out, while the AppRootView (and its @Query observers) are 
        // completely detached from the view hierarchy. This prevents SwiftData crashes.
        
        // Set anonymous session state
        currentUserId = nil
        isAnonymousSession = true
        print("DEBUG: Anonymous session initialized")
    }
    
    /// Sync daily goal to Firestore
    func syncDailyGoalToCloud(_ goal: Double) async {
        // Only sync if user is signed in (not anonymous)
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            print("DEBUG: User is anonymous or not signed in, skipping cloud sync for daily goal")
            return
        }
        
        do {
            try await firestoreService.saveDailyGoal(goal)
            print("DEBUG: Successfully synced daily goal to cloud: \(goal)")
        } catch {
            print("DEBUG: Error syncing daily goal to cloud: \(error)")
            syncError = "Failed to sync daily goal to cloud: \(error.localizedDescription)"
        }
    }
    
    /// Fetch daily goal from Firestore
    func fetchDailyGoalFromCloud() async -> Double? {
        // Only fetch if user is signed in (not anonymous)
        guard let user = Auth.auth().currentUser, !user.isAnonymous else {
            print("DEBUG: User is anonymous or not signed in, skipping cloud fetch for daily goal")
            return nil
        }
        
        print("DEBUG: Fetching daily goal from cloud for user: \(user.uid)")
        do {
            let goal = try await firestoreService.fetchDailyGoal()
            print("DEBUG: fetchDailyGoalFromCloud result: \(goal?.description ?? "nil")")
            return goal
        } catch {
            print("DEBUG: Error fetching daily goal from cloud: \(error)")
            syncError = "Failed to fetch daily goal from cloud: \(error.localizedDescription)"
            return nil
        }
    }
}

