//
//  logcalApp.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth

@main
struct logcalApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showAuthView = false
    
    init() {
        print("DEBUG: App initializing...")
        // Initialize Firebase
        FirebaseApp.configure()
        print("DEBUG: Firebase configured")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showAuthView {
                    AuthView(isPresented: $showAuthView)
                } else {
                    TabView {
                        HomeView()
                            .tabItem {
                                Label("Log", systemImage: "plus.circle")
                            }
                        
                        HistoryView()
                            .tabItem {
                                Label("History", systemImage: "list.bullet")
                            }
                    }
                    .modelContainer(for: MealEntry.self)
                }
            }
            .task {
                // Check if we should show auth view
                // Show if no user exists OR if user is anonymous (give them option to upgrade)
                // Use .task instead of .onAppear to ensure Firebase is fully initialized
                let currentUser = Auth.auth().currentUser
                print("DEBUG: Checking auth state - currentUser: \(currentUser?.uid ?? "nil"), isAnonymous: \(currentUser?.isAnonymous ?? false)")
                
                if currentUser == nil {
                    // No user at all - show auth view on first launch
                    print("DEBUG: No user found, showing auth view")
                    showAuthView = true
                } else if let user = currentUser, user.isAnonymous {
                    // User is anonymous - show auth view to give option to sign in
                    print("DEBUG: Anonymous user found, showing auth view for upgrade option")
                    showAuthView = true
                } else {
                    // User is signed in with Google - don't show auth view
                    print("DEBUG: User is signed in (not anonymous), hiding auth view")
                    showAuthView = false
                }
            }
            .onChange(of: authViewModel.isSignedIn) { oldValue, newValue in
                // Hide auth view when user signs in
                if newValue {
                    showAuthView = false
                } else {
                    // Show auth view when user signs out
                    showAuthView = true
                }
            }
            .onChange(of: authViewModel.currentUser) { oldValue, newValue in
                // Show auth view when user becomes nil (signed out)
                if newValue == nil {
                    showAuthView = true
                }
            }
        }
    }
}
