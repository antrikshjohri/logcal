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
    
    var body: some View {
        Color.clear
            .task {
                // Sync from cloud on app launch if user is signed in
                if let user = Auth.auth().currentUser, !user.isAnonymous {
                    print("DEBUG: User is signed in, syncing from cloud...")
                    await cloudSyncService.syncFromCloud(modelContext: modelContext)
                }
            }
            .onChange(of: authViewModel.currentUser) { oldValue, newValue in
                // Handle sync when user signs in
                if let newUser = newValue, !newUser.isAnonymous {
                    let wasAnonymous = oldValue?.isAnonymous == true
                    let wasNil = oldValue == nil
                    
                    if wasAnonymous || wasNil {
                        // User just signed in (not anonymous) - sync data
                        Task {
                            print("DEBUG: User signed in, migrating and syncing data...")
                            // First migrate local data to cloud
                            await cloudSyncService.migrateLocalToCloud(modelContext: modelContext)
                            // Then fetch any cloud data
                            await cloudSyncService.syncFromCloud(modelContext: modelContext)
                        }
                    }
                }
            }
    }
}

