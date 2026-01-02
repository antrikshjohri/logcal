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
    @StateObject private var toastManager = ToastManager()
    @State private var showAuthView = false
    @State private var isInitialSyncAfterSignIn = false
    @State private var selectedTab: Int = 0
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
                        .toastNotification(toastManager: toastManager)
                        .environmentObject(toastManager)
                } else {
                    ZStack {
                        TabView(selection: $selectedTab) {
                            DashboardView()
                                .tabItem {
                                    Label("Home", systemImage: "house.fill")
                                }
                                .tag(0)
                            
                            HomeView()
                                .tabItem {
                                    Label("Log", systemImage: "plus.circle")
                                }
                                .tag(1)
                            
                            HistoryView(selectedTab: $selectedTab)
                                .tabItem {
                                    Label("History", systemImage: "list.bullet")
                                }
                                .tag(2)
                            
                            ProfileView()
                                .tabItem {
                                    Label("Profile", systemImage: "person.fill")
                                }
                                .tag(3)
                        }
                        
                        // SyncHandlerView as an overlay to ensure it has access to the same modelContext
                        SyncHandlerView(cloudSyncService: cloudSyncService, authViewModel: authViewModel)
                            .allowsHitTesting(false) // Don't intercept touches
                        
                        // Loading overlay while syncing after sign-in
                        if cloudSyncService.isSyncing && isInitialSyncAfterSignIn {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Loading your meals...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground).opacity(0.9))
                        }
                    }
                    .modelContainer(for: MealEntry.self)
                    .environmentObject(cloudSyncService)
                    .environmentObject(authViewModel)
                    .toastNotification(toastManager: toastManager)
                    .environmentObject(toastManager)
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
                // #region agent log
                DebugLogger.log(location: "logcalApp.swift:83", message: "isSignedIn changed", data: ["oldValue": oldValue, "newValue": newValue, "userId": authViewModel.currentUser?.uid ?? "nil"], hypothesisId: "C")
                // #endregion
                // Hide auth view when user signs in
                if newValue {
                    showAuthView = false
                    // Mark that we're doing initial sync after sign-in
                    isInitialSyncAfterSignIn = true
                    // Navigate to HomeView (Log tab) when user signs in
                    selectedTab = 1
                } else {
                    // Show auth view when user signs out
                    showAuthView = true
                    isInitialSyncAfterSignIn = false
                }
            }
            .onChange(of: authViewModel.currentUser) { oldValue, newValue in
                // #region agent log
                DebugLogger.log(location: "logcalApp.swift:96", message: "currentUser changed in logcalApp", data: ["oldUserId": oldValue?.uid ?? "nil", "newUserId": newValue?.uid ?? "nil", "oldIsAnonymous": oldValue?.isAnonymous ?? false, "newIsAnonymous": newValue?.isAnonymous ?? false], hypothesisId: "C")
                // #endregion
                
                // Show auth view when user becomes nil (signed out)
                if newValue == nil {
                    showAuthView = true
                }
                // Trigger sync when user signs in (not anonymous)
                else if let newUser = newValue, !newUser.isAnonymous {
                    let wasNil = oldValue == nil
                    let wasAnonymous = oldValue?.isAnonymous == true
                    
                    // If user just signed in (was nil or anonymous), trigger sync immediately
                    if wasNil || wasAnonymous {
                        // #region agent log
                        DebugLogger.log(location: "logcalApp.swift:108", message: "User signed in, triggering sync", data: ["wasNil": wasNil, "wasAnonymous": wasAnonymous, "userId": newUser.uid], hypothesisId: "C")
                        // #endregion
                        // Navigate to HomeView (Log tab) when user signs in
                        selectedTab = 1
                        Task {
                            // Wait a moment for TabView to be created and modelContext to be available
                            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                            
                            // Get modelContext from the TabView if available
                            // Since we can't access modelContext here directly, we'll rely on SyncHandlerView
                            // But we can ensure the sync happens by checking if TabView is visible
                            if !showAuthView {
                                // TabView should be visible now, SyncHandlerView will handle the sync
                                print("DEBUG: TabView should be visible, SyncHandlerView will sync")
                            }
                        }
                    }
                }
            }
            .onChange(of: cloudSyncService.isSyncing) { oldValue, newValue in
                // When sync completes, hide the loading overlay
                if oldValue && !newValue && isInitialSyncAfterSignIn {
                    // Small delay to ensure UI updates smoothly
                    Task {
                        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                        isInitialSyncAfterSignIn = false
                    }
                }
            }
        }
    }
    
    // Get current theme from AppStorage
    private var appTheme: AppTheme {
        AppTheme(rawValue: appThemeString) ?? .system
    }
}
