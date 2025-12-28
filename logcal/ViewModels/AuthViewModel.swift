//
//  AuthViewModel.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import UIKit

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var userName: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen to auth state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.updateUserName()
        }
        
        // Set initial user
        currentUser = Auth.auth().currentUser
        updateUserName()
    }
    
    deinit {
        // Remove listener when view model is deallocated
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    /// Get display name from user (from social profile or email)
    func updateUserName() {
        guard let user = currentUser else {
            userName = nil
            return
        }
        
        // Try to get name from profile
        if let displayName = user.displayName, !displayName.isEmpty {
            userName = displayName
        } else if let email = user.email {
            // Use email username as fallback
            userName = String(email.split(separator: "@").first ?? "")
        } else {
            userName = nil
        }
    }
    
    /// Check if user is signed in (not anonymous)
    var isSignedIn: Bool {
        guard let user = currentUser else { return false }
        // Anonymous users have isAnonymous = true
        return !user.isAnonymous
    }
    
    /// Sign in with Google
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Google Sign-In not configured. Please check your GoogleService-Info.plist"
            isLoading = false
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Could not find root view controller"
            isLoading = false
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AppError.unknown(NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"]))
            }
            
            // Create Google Auth credential
            // Use GoogleAuthProvider which is the standard way for Google Sign-In with Firebase
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            
            print("DEBUG: Google sign-in successful: \(authResult.user.email ?? "no email")")
            isLoading = false
        } catch {
            print("DEBUG: Google sign-in error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    /// Handle Apple Sign-In authorization result
    func handleAppleSignIn(authorization: ASAuthorization) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = appleIDCredential.identityToken,
                  let idTokenString = String(data: idTokenData, encoding: .utf8) else {
                throw AppError.unknown(NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get Apple ID token"]))
            }
            
            // Create Firebase credential for Apple Sign-In
            // Use the dedicated Apple Sign-In credential method
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nil,
                fullName: appleIDCredential.fullName
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            
            print("DEBUG: Apple sign-in successful: \(authResult.user.email ?? "no email")")
            isLoading = false
        } catch {
            print("DEBUG: Apple sign-in error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    /// Sign in anonymously (skip authentication)
    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await Auth.auth().signInAnonymously()
            print("DEBUG: Anonymous sign-in successful")
            isLoading = false
        } catch {
            print("DEBUG: Anonymous sign-in error: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    /// Sign out
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("DEBUG: Sign out successful")
        } catch {
            print("DEBUG: Sign out error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}


