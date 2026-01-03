//
//  AppConfigService.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import Combine
import FirebaseFirestore

struct AppConfig: Codable {
    let minimumAppVersion: String
    let updateMessage: String?
    let appStoreURL: String?
    let lastUpdatedTimestamp: TimeInterval?
    
    var lastUpdated: Date? {
        guard let timestamp = lastUpdatedTimestamp else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    static let `default` = AppConfig(
        minimumAppVersion: "1.0",
        updateMessage: nil,
        appStoreURL: nil,
        lastUpdatedTimestamp: nil
    )
}

@MainActor
class AppConfigService: ObservableObject {
    private let db = Firestore.firestore()
    private let configCacheKey = "appConfigCache"
    private let cacheExpirationKey = "appConfigCacheExpiration"
    private let cachedAppVersionKey = "appConfigCachedAppVersion"
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    
    @Published var appConfig: AppConfig = .default
    @Published var isLoading: Bool = false
    
    init() {
        // Clear cache if app version has changed (user updated the app)
        checkAndClearCacheIfVersionChanged()
    }
    
    /// Get current app version
    static var currentAppVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version).\(build)"
    }
    
    /// Get marketing version only (e.g., "1.0")
    static var currentMarketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// Fetch app config from Firestore
    func fetchConfig() async {
        isLoading = true
        
        // Check cache first (but only if app version hasn't changed)
        if let cachedConfig = getCachedConfig(), 
           !isCacheExpired(),
           getCachedAppVersion() == Self.currentMarketingVersion {
            print("DEBUG: Using cached app config")
            appConfig = cachedConfig
            isLoading = false
            return
        }
        
        do {
            let document = try await db.collection("app").document("config").getDocument()
            
            if document.exists, let data = document.data() {
                let lastUpdatedTimestamp = (data["lastUpdated"] as? Timestamp)?.dateValue().timeIntervalSince1970
                let config = AppConfig(
                    minimumAppVersion: data["minimumAppVersion"] as? String ?? "1.0",
                    updateMessage: data["updateMessage"] as? String,
                    appStoreURL: data["appStoreURL"] as? String,
                    lastUpdatedTimestamp: lastUpdatedTimestamp
                )
                
                appConfig = config
                cacheConfig(config)
                // Store current app version with cache
                UserDefaults.standard.set(Self.currentMarketingVersion, forKey: cachedAppVersionKey)
                print("DEBUG: Fetched app config from Firestore: minimumVersion=\(config.minimumAppVersion)")
            } else {
                print("DEBUG: App config document does not exist, using default")
                appConfig = .default
            }
        } catch {
            print("DEBUG: Error fetching app config: \(error)")
            // Use cached config if available, otherwise use default
            if let cachedConfig = getCachedConfig() {
                appConfig = cachedConfig
            } else {
                appConfig = .default
            }
        }
        
        isLoading = false
    }
    
    /// Check if current app version meets minimum requirement
    func isAppVersionValid() -> Bool {
        let currentVersion = Self.currentMarketingVersion
        let minimumVersion = appConfig.minimumAppVersion
        
        return compareVersions(currentVersion, minimumVersion) >= 0
    }
    
    /// Compare two version strings (e.g., "1.0" vs "2.0")
    /// Returns: -1 if current < minimum, 0 if equal, 1 if current > minimum
    private func compareVersions(_ current: String, _ minimum: String) -> Int {
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let minimumParts = minimum.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(currentParts.count, minimumParts.count)
        
        for i in 0..<maxLength {
            let currentPart = i < currentParts.count ? currentParts[i] : 0
            let minimumPart = i < minimumParts.count ? minimumParts[i] : 0
            
            if currentPart < minimumPart {
                return -1
            } else if currentPart > minimumPart {
                return 1
            }
        }
        
        return 0
    }
    
    /// Get App Store URL (from config or default)
    func getAppStoreURL() -> URL? {
        if let urlString = appConfig.appStoreURL, let url = URL(string: urlString) {
            return url
        }
        // Default App Store URL format (you'll need to replace with your actual App ID)
        // Format: https://apps.apple.com/app/id<APP_ID>
        return nil
    }
    
    // MARK: - Cache Management
    
    private func cacheConfig(_ config: AppConfig) {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: configCacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheExpirationKey)
        }
    }
    
    private func getCachedConfig() -> AppConfig? {
        guard let data = UserDefaults.standard.data(forKey: configCacheKey),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return nil
        }
        return config
    }
    
    private func isCacheExpired() -> Bool {
        let expirationTime = UserDefaults.standard.double(forKey: cacheExpirationKey)
        if expirationTime == 0 {
            return true
        }
        let expirationDate = Date(timeIntervalSince1970: expirationTime)
        return Date() > expirationDate.addingTimeInterval(cacheExpirationInterval)
    }
    
    private func getCachedAppVersion() -> String? {
        return UserDefaults.standard.string(forKey: cachedAppVersionKey)
    }
    
    /// Clear cache if app version has changed (user updated the app)
    private func checkAndClearCacheIfVersionChanged() {
        let cachedVersion = getCachedAppVersion()
        let currentVersion = Self.currentMarketingVersion
        
        if let cached = cachedVersion, cached != currentVersion {
            print("DEBUG: App version changed from \(cached) to \(currentVersion), clearing config cache")
            clearCache()
        } else if cachedVersion == nil {
            // First time running, no cache exists yet
            print("DEBUG: First run, no cached config")
        }
    }
    
    /// Clear the config cache
    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: configCacheKey)
        UserDefaults.standard.removeObject(forKey: cacheExpirationKey)
        UserDefaults.standard.removeObject(forKey: cachedAppVersionKey)
    }
}

