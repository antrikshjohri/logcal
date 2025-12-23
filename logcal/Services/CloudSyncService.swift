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
            return
        }
        
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
                try modelContext.save()
                print("DEBUG: Added \(addedCount) meals from cloud to local storage")
            }
            
            isSyncing = false
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
}

