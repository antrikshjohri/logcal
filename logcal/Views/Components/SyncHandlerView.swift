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
    @StateObject private var authViewModel = AuthViewModel()
    @State private var hasSyncedOnLaunch = false
    
    var body: some View {
        Color.clear
            .task {
                // Wait a bit to ensure modelContext is ready
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Sync from cloud on app launch if user is signed in
                if let user = Auth.auth().currentUser, !user.isAnonymous {
                    print("DEBUG: User is signed in on launch, syncing from cloud...")
                    await cloudSyncService.syncFromCloud(modelContext: modelContext)
                    hasSyncedOnLaunch = true
                }
            }
            .onChange(of: authViewModel.currentUser) { oldValue, newValue in
                // Handle user sign out
                if oldValue != nil && newValue == nil {
                    // User signed out - clear local data
                    print("DEBUG: User signed out, clearing local data...")
                    Task {
                        await cloudSyncService.clearLocalMeals(modelContext: modelContext)
                    }
                }
                // Handle sync when user signs in or switches accounts
                else if let newUser = newValue, !newUser.isAnonymous {
                    let wasAnonymous = oldValue?.isAnonymous == true
                    let wasNil = oldValue == nil
                    let oldUserId = oldValue?.uid
                    let newUserId = newUser.uid
                    let userChanged = oldUserId != nil && oldUserId != newUserId
                    
                    if wasAnonymous || wasNil || userChanged {
                        // User just signed in (not anonymous) or switched accounts - sync data
                        Task {
                            // Wait a bit to ensure modelContext is ready
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            
                            if userChanged {
                                print("DEBUG: User switched accounts, syncing new user's data...")
                                // For account switch, syncFromCloud will clear old data automatically
                                await cloudSyncService.syncFromCloud(modelContext: modelContext)
                            } else {
                                print("DEBUG: User signed in, migrating and syncing data...")
                                // First migrate local data to cloud (only if there are local meals)
                                await cloudSyncService.migrateLocalToCloud(modelContext: modelContext)
                                // Then fetch any cloud data
                                await cloudSyncService.syncFromCloud(modelContext: modelContext)
                            }
                        }
                    }
                }
            }
            .onAppear {
                // Also try to sync when view appears (as a fallback)
                if !hasSyncedOnLaunch {
                    Task {
                        if let user = Auth.auth().currentUser, !user.isAnonymous {
                            print("DEBUG: SyncHandlerView appeared, syncing from cloud...")
                            await cloudSyncService.syncFromCloud(modelContext: modelContext)
                            hasSyncedOnLaunch = true
                        }
                    }
                }
            }
    }
}

