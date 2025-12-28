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
import FirebaseFirestore

@main
struct logcalApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cloudSyncService = CloudSyncService()
    @State private var showAuthView = false
    @AppStorage("appTheme") private var appThemeString: String = AppTheme.system.rawValue
    
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
                        DashboardView()
                            .tabItem {
                                Label("Home", systemImage: "house.fill")
                            }
                        
                        HomeView()
                            .tabItem {
                                Label("Log", systemImage: "plus.circle")
                            }
                        
                        HistoryView()
                            .tabItem {
                                Label("History", systemImage: "list.bullet")
                            }
                        
                        ProfileView()
                            .tabItem {
                                Label("Profile", systemImage: "person.fill")
                            }
                    }
                    .modelContainer(for: MealEntry.self)
                    .environmentObject(cloudSyncService)
                    .background(SyncHandlerView(cloudSyncService: cloudSyncService))
                }
            }
            .preferredColorScheme(appTheme.colorScheme)
            .task {
                // Check if we should show auth view
                // Show if no user exists (sign-in is mandatory)
                // Use .task instead of .onAppear to ensure Firebase is fully initialized
                let currentUser = Auth.auth().currentUser
                print("DEBUG: Checking auth state - currentUser: \(currentUser?.uid ?? "nil"), isAnonymous: \(currentUser?.isAnonymous ?? false)")
                
                if currentUser == nil {
                    // No user at all - show auth view (sign-in required)
                    print("DEBUG: No user found, showing auth view")
                    showAuthView = true
                } else if let user = currentUser, user.isAnonymous {
                    // Anonymous user - sign them out and show auth view (sign-in required)
                    print("DEBUG: Anonymous user found, signing out and showing auth view")
                    try? Auth.auth().signOut()
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
    
    // Get current theme from AppStorage
    private var appTheme: AppTheme {
        AppTheme(rawValue: appThemeString) ?? .system
    }
}
