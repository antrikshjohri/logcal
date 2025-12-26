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
            print("DEBUG: Switching from anonymous to authenticated user, clearing anonymous data...")
            await clearLocalMeals(modelContext: modelContext)
            isAnonymousSession = false
        }
        
        // Check if user has changed (different authenticated account signed in)
        if let previousUserId = currentUserId, previousUserId != newUserId {
            print("DEBUG: User changed from \(previousUserId) to \(newUserId), clearing local data first...")
            await clearLocalMeals(modelContext: modelContext)
        }
        // If currentUserId is nil but we have local data, we're signing in after sign-out
        // Clear the old user's data before syncing new user's data
        else if currentUserId == nil {
            let descriptor = FetchDescriptor<MealEntry>()
            if let localMeals = try? modelContext.fetch(descriptor), !localMeals.isEmpty {
                print("DEBUG: Signing in after sign-out, clearing previous user's local data...")
                await clearLocalMeals(modelContext: modelContext)
            }
        }
        
        // Update current user ID and session type
        currentUserId = newUserId
        isAnonymousSession = false
        
        isSyncing = true
        syncError = nil
        
        do {
            // Fetch from Firestore
            let cloudMeals = try await firestoreService.fetchMealEntries()
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
                // Save the context
                try modelContext.save()
                print("DEBUG: Added \(addedCount) meals from cloud to local storage")
                
                // Verify the save worked by checking local meals again
                let verifyDescriptor = FetchDescriptor<MealEntry>()
                let verifyMeals = try modelContext.fetch(verifyDescriptor)
                print("DEBUG: After save, found \(verifyMeals.count) local meals")
                
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
        do {
            let descriptor = FetchDescriptor<MealEntry>()
            let localMeals = try modelContext.fetch(descriptor)
            print("DEBUG: Found \(localMeals.count) local meals to delete")
            
            for meal in localMeals {
                modelContext.delete(meal)
            }
            
            try modelContext.save()
            print("DEBUG: Successfully cleared \(localMeals.count) local meals")
            
            // Clear session state when clearing local data
            currentUserId = nil
            isAnonymousSession = false
        } catch {
            print("DEBUG: Error clearing local meals: \(error)")
            syncError = "Failed to clear local meals: \(error.localizedDescription)"
        }
    }
    
    /// Initialize anonymous session (clear authenticated data when switching to anonymous)
    func initializeAnonymousSession(modelContext: ModelContext) async {
        print("DEBUG: Initializing anonymous session...")
        
        // If we were in an authenticated session, clear that data
        if let previousUserId = currentUserId {
            print("DEBUG: Clearing authenticated user data before switching to anonymous...")
            await clearLocalMeals(modelContext: modelContext)
        }
        // If currentUserId is nil but we have local data, we're switching to anonymous after sign-out
        // Clear the old user's data
        else {
            let descriptor = FetchDescriptor<MealEntry>()
            if let localMeals = try? modelContext.fetch(descriptor), !localMeals.isEmpty {
                print("DEBUG: Switching to anonymous after sign-out, clearing previous user's local data...")
                await clearLocalMeals(modelContext: modelContext)
            }
        }
        
        // Set anonymous session state
        currentUserId = nil
        isAnonymousSession = true
        print("DEBUG: Anonymous session initialized")
    }
}

