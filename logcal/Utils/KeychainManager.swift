//
//  KeychainManager.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import Security

enum KeychainManager {
    private static let service = "com.logcal.api"
    private static let apiKeyKey = "openai_api_key"
    
    /// Save API key to Keychain
    static func saveAPIKey(_ key: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw AppError.dataConversionError
        }
        
        // Delete existing item if it exists
        deleteAPIKey()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw AppError.unknown(NSError(domain: NSOSStatusErrorDomain, code: Int(status)))
        }
    }
    
    /// Retrieve API key from Keychain
    static func getAPIKey() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw AppError.apiKeyNotFound
        }
        
        return apiKey
    }
    
    /// Delete API key from Keychain
    static func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// Check if API key exists in Keychain
    static func hasAPIKey() -> Bool {
        do {
            _ = try getAPIKey()
            return true
        } catch {
            return false
        }
    }
}

