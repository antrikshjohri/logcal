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
import FirebaseAnalytics
import UserNotifications

@main
struct logcalApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cloudSyncService = CloudSyncService()
    @StateObject private var toastManager = ToastManager()
    @State private var showAuthView = false
    @State private var isInitialSyncAfterSignIn = false
    @State private var selectedTab: Int = 0
    @AppStorage("appTheme", store: UserDefaults(suiteName: "group.com.serene.logcal")) private var appThemeString: String = AppTheme.system.rawValue
    @AppStorage("mealRemindersEnabled", store: UserDefaults(suiteName: "group.com.serene.logcal")) private var mealRemindersEnabled: Bool = true
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Shared container to allow background access
    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MealEntry.self,
            SavedMeal.self,
        ])
        let appGroup = "group.com.serene.logcal"
        let fileManager = FileManager.default
        let modelConfiguration: ModelConfiguration
        
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            let storeURL = containerURL.appendingPathComponent("default.store")
            modelConfiguration = ModelConfiguration(url: storeURL)
            print("DEBUG: ModelContainer using shared URL: \(storeURL.path)")
        } else {
            modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)
            print("DEBUG: ModelContainer using default URL (fallback)")
        }
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        print("DEBUG: App initializing...")
        // Migrate data to App Group shared container first
        migrateUserDefaultsToSharedContainerIfNeeded()
        migrateToSharedContainerIfNeeded()
        
        // Initialize Firebase
        FirebaseApp.configure()
        print("DEBUG: Firebase configured")
        
        // Initialize Firebase Analytics
        print("DEBUG: Firebase Analytics initialized")
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        print("DEBUG: Notification delegate configured")
    }
    
    private func migrateToSharedContainerIfNeeded() {
        let appGroup = "group.com.serene.logcal"
        let fileManager = FileManager.default
        
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let defaultStoreURL = appSupportURL.appendingPathComponent("default.store")
        let defaultShmURL = appSupportURL.appendingPathComponent("default.store-shm")
        let defaultWalURL = appSupportURL.appendingPathComponent("default.store-wal")
        
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            print("DEBUG: Shared container not available for SwiftData migration")
            return
        }
        let sharedStoreURL = containerURL.appendingPathComponent("default.store")
        let sharedShmURL = containerURL.appendingPathComponent("default.store-shm")
        let sharedWalURL = containerURL.appendingPathComponent("default.store-wal")
        
        if fileManager.fileExists(atPath: sharedStoreURL.path) {
            print("DEBUG: Shared store already exists, skipping SwiftData migration")
            return
        }
        
        if fileManager.fileExists(atPath: defaultStoreURL.path) {
            print("DEBUG: Found default SwiftData store, migrating to shared container...")
            do {
                try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: nil)
                try fileManager.copyItem(at: defaultStoreURL, to: sharedStoreURL)
                
                if fileManager.fileExists(atPath: defaultShmURL.path) {
                    try fileManager.copyItem(at: defaultShmURL, to: sharedShmURL)
                }
                
                if fileManager.fileExists(atPath: defaultWalURL.path) {
                    try fileManager.copyItem(at: defaultWalURL, to: sharedWalURL)
                }
                print("DEBUG: SwiftData database successfully migrated to shared container.")
            } catch {
                print("DEBUG: Failed to migrate SwiftData database: \(error)")
            }
        }
    }
    
    private func migrateUserDefaultsToSharedContainerIfNeeded() {
        let appGroup = "group.com.serene.logcal"
        guard let sharedDefaults = UserDefaults(suiteName: appGroup) else { return }
        let standardDefaults = UserDefaults.standard
        
        if !sharedDefaults.bool(forKey: "didMigrateUserDefaults") {
            let keysToMigrate = [
                "dailyGoal", "proteinGoal", "carbsGoal", "fatGoal", "dietStyle",
                "customProteinPercent", "customCarbsPercent", "customFatPercent",
                "appTheme", "mealRemindersEnabled"
            ]
            
            for key in keysToMigrate {
                if let value = standardDefaults.value(forKey: key) {
                    sharedDefaults.set(value, forKey: key)
                }
            }
            sharedDefaults.set(true, forKey: "didMigrateUserDefaults")
            sharedDefaults.synchronize()
            print("DEBUG: UserDefaults successfully migrated to shared container.")
        }
    }
    
    private var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: "group.com.serene.logcal") ?? UserDefaults.standard
    }
    
    private func handleDeepLink(_ url: URL) {
        guard let host = url.host else { return }
        print("DEBUG: Received deep link: \(url.absoluteString)")
        
        if host == "dashboard" {
            selectedTab = 0
            AnalyticsService.trackDeepLinkOpened(host: "dashboard", action: nil as String?)
        } else if host == "log" {
            selectedTab = 1
            
            // Parse query parameters
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let action = components?.queryItems?.first(where: { $0.name == "action" })?.value
            let mealType = components?.queryItems?.first(where: { $0.name == "mealType" })?.value
            
            AnalyticsService.trackDeepLinkOpened(host: "log", action: action)
            
            // Save to UserDefaults as a backup for cold start
            let defaults = UserDefaults.standard
            defaults.set(action, forKey: "pendingDeepLinkAction")
            defaults.set(mealType, forKey: "pendingDeepLinkMealType")
            
            // Post notification for HomeView/LogViewModel to handle
            NotificationCenter.default.post(
                name: NSNotification.Name("HandleDeepLinkAction"),
                object: nil,
                userInfo: [
                    "action": action as Any,
                    "mealType": mealType as Any
                ]
            )
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showAuthView {
                    AuthView(isPresented: $showAuthView)
                        .toastNotification(toastManager: toastManager)
                        .environmentObject(toastManager)
                } else {
                    AppRootView(
                        selectedTab: $selectedTab,
                        isInitialSyncAfterSignIn: $isInitialSyncAfterSignIn
                    )
                    .modelContainer(logcalApp.sharedModelContainer)
                    .environmentObject(cloudSyncService)
                    .environmentObject(authViewModel)
                    .toastNotification(toastManager: toastManager)
                    .environmentObject(toastManager)
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenLogTab"))) { notification in
                        // Handle notification tap - navigate to Log tab
                        selectedTab = 1
                        
                        // Post meal type if available
                        if let userInfo = notification.userInfo,
                           let mealTypeString = userInfo["mealType"] as? String {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("SetMealTypeFromNotification"),
                                object: nil,
                                userInfo: ["mealType": mealTypeString]
                            )
                        }
                    }
                }
            }
            .preferredColorScheme(appTheme.colorScheme)
            .task {
                // Check if we should show auth view
                // Show if no user exists (sign-in/guest is mandatory)
                // Use .task instead of .onAppear to ensure Firebase is fully initialized
                let currentUser = Auth.auth().currentUser
                print("DEBUG: Checking auth state - currentUser: \(currentUser?.uid ?? "nil"), isAnonymous: \(currentUser?.isAnonymous ?? false)")
                
                if currentUser == nil {
                    // No user at all - show auth view (sign-in required)
                    print("DEBUG: No user found, showing auth view")
                    showAuthView = true
                } else {
                    // User is signed in (either anonymous guest or Google/Apple) - don't show auth view
                    print("DEBUG: User is signed in, hiding auth view")
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
                    // Safely clear local data here since AppRootView (and its @Query observers) 
                    // is removed from the view hierarchy when showAuthView is true.
                    Task {
                        // Wait a tiny bit for the view transition to complete
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        let bgContext = ModelContext(logcalApp.sharedModelContainer)
                        await cloudSyncService.clearLocalMeals(modelContext: bgContext)
                    }
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
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .defaultAppStorage(sharedUserDefaults)
        }
    }
    
    // Get current theme from AppStorage
    private var appTheme: AppTheme {
        AppTheme(rawValue: appThemeString) ?? .system
    }
}

struct AppRootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var cloudSyncService: CloudSyncService
    @EnvironmentObject private var toastManager: ToastManager
    @Binding var selectedTab: Int
    @Binding var isInitialSyncAfterSignIn: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ZStack {
            if horizontalSizeClass == .regular {
                NavigationSplitView {
                    List(selection: Binding<Int?>(
                        get: { selectedTab },
                        set: { if let val = $0 { selectedTab = val } }
                    )) {
                        NavigationLink(value: 0) {
                            Label("Home", systemImage: "house.fill")
                        }
                        NavigationLink(value: 1) {
                            Label("Log", systemImage: "plus.circle")
                        }
                        NavigationLink(value: 2) {
                            Label("History", systemImage: "list.bullet")
                        }
                        NavigationLink(value: 3) {
                            Label("Profile", systemImage: "person.fill")
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .navigationTitle("LogCal")
                } detail: {
                    Group {
                        switch selectedTab {
                        case 0:
                            DashboardView(selectedTab: $selectedTab)
                        case 1:
                            HomeView()
                        case 2:
                            HistoryView(selectedTab: $selectedTab)
                        case 3:
                            ProfileView()
                        default:
                            DashboardView(selectedTab: $selectedTab)
                        }
                    }
                    .tint(Theme.primaryGreen)
                }
                .onChange(of: selectedTab) { oldValue, newValue in
                    let tabNames = ["Dashboard", "Log", "History", "Profile"]
                    if newValue < tabNames.count {
                        AnalyticsService.trackTabChanged(tabName: tabNames[newValue])
                        AnalyticsService.trackViewOpened(viewName: tabNames[newValue])
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    DashboardView(selectedTab: $selectedTab)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                        .onAppear {
                            if selectedTab == 0 {
                                AnalyticsService.trackViewOpened(viewName: "Dashboard")
                            }
                        }
                    
                    HomeView()
                        .tabItem {
                            Label("Log", systemImage: "plus.circle")
                        }
                        .tag(1)
                        .onAppear {
                            if selectedTab == 1 {
                                AnalyticsService.trackViewOpened(viewName: "Log")
                            }
                        }
                    
                    HistoryView(selectedTab: $selectedTab)
                        .tabItem {
                            Label("History", systemImage: "list.bullet")
                        }
                        .tag(2)
                        .onAppear {
                            if selectedTab == 2 {
                                AnalyticsService.trackViewOpened(viewName: "History")
                            }
                        }
                    
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                        .tag(3)
                        .onAppear {
                            if selectedTab == 3 {
                                AnalyticsService.trackViewOpened(viewName: "Profile")
                            }
                        }
                }
                .tint(Theme.primaryGreen)
                .onChange(of: selectedTab) { oldValue, newValue in
                    let tabNames = ["Dashboard", "Log", "History", "Profile"]
                    if newValue < tabNames.count {
                        AnalyticsService.trackTabChanged(tabName: tabNames[newValue])
                    }
                }
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
    }
}

