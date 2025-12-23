//
//  Secrets.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation

struct Secrets {
    /// Get API key with fallback priority:
    /// 1. Keychain (most secure, for production)
    /// 2. Secrets.plist (for development/setup)
    static func getAPIKey() throws -> String {
        // First, try Keychain (most secure)
        if let keychainKey = try? KeychainManager.getAPIKey() {
            return keychainKey
        }
        
        // Fallback to Secrets.plist (for initial setup)
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let apiKey = plist["OPENAI_API_KEY"] as? String {
            // Migrate to Keychain for future use
            try? KeychainManager.saveAPIKey(apiKey)
            return apiKey
        }
        
        throw AppError.apiKeyNotFound
    }
    
    /// Save API key to Keychain (for user input or migration)
    static func saveAPIKey(_ key: String) throws {
        try KeychainManager.saveAPIKey(key)
    }
    
    /// Check if API key is configured
    static func hasAPIKey() -> Bool {
        return KeychainManager.hasAPIKey() || 
               (Bundle.main.path(forResource: "Secrets", ofType: "plist") != nil)
    }
}

