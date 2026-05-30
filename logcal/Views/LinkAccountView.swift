//
//  LinkAccountView.swift
//  logcal
//
//  Created by Antriksh Johri on 29/05/26.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import SwiftData

struct LinkAccountView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var toastManager: ToastManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    private let showAppleSignIn = true
    
    // Store Apple Sign-In delegates to prevent deallocation
    @State private var appleSignInDelegate: AppleSignInDelegate?
    @State private var appleSignInPresentationContext: AppleSignInPresentationContextProvider?
    @State private var showConflictSheet = false
    
    var body: some View {
        ZStack {
            // Background
            Theme.backgroundColor(colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: Constants.Spacing.extraLarge) {
                // Header
                VStack(spacing: Constants.Spacing.medium) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.primaryGreen)
                        .padding(.top, 40)
                    
                    Text("Link Your Account")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Sign in with Google or Apple to back up your calorie logs to the cloud and sync them across devices.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                }
                
                Spacer()
                
                // Auth Provider Buttons
                VStack(spacing: Constants.Spacing.regular) {
                    if showAppleSignIn {
                        AuthProviderButton(
                            provider: .apple,
                            isDisabled: authViewModel.isLoading
                        ) {
                            handleAppleSignIn()
                        }
                    }
                    
                    AuthProviderButton(
                        provider: .google,
                        isDisabled: authViewModel.isLoading
                    ) {
                        Task {
                            await authViewModel.linkWithGoogle()
                            if authViewModel.isSignedIn && !authViewModel.isAnonymous {
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal, Constants.Spacing.extraLarge)
                
                if authViewModel.isLoading {
                    ProgressView()
                        .padding(.vertical)
                }
                
                Spacer()
                
                // Footer / Close
                Button(action: {
                    dismiss()
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .padding(.vertical, 8)
                }
                .disabled(authViewModel.isLoading)
                .padding(.bottom, 20)
            }
        }
        .onChange(of: authViewModel.errorMessage) { oldValue, newValue in
            if newValue == "CREDENTIAL_ALREADY_IN_USE" {
                // Check if there are local guest meals to merge
                let descriptor = FetchDescriptor<MealEntry>()
                let hasLocalMeals = (try? modelContext.fetch(descriptor))?.isEmpty == false
                
                if hasLocalMeals {
                    showConflictSheet = true
                } else {
                    // No guest data exists: automatically switch to the existing account and dismiss
                    print("DEBUG: No local guest meals found, automatically switching to existing account...")
                    Task { @MainActor in
                        authViewModel.shouldMergeOnSwitch = false
                        await authViewModel.switchAccountWithPendingCredential()
                        dismiss()
                    }
                }
            } else if let message = newValue, message != oldValue {
                toastManager.show(ToastMessage(
                    title: "Linking Error",
                    message: message,
                    type: .error
                ))
            }
        }
        .sheet(isPresented: $showConflictSheet) {
            ConflictResolutionView(
                onResolve: { resolution in
                    Task {
                        authViewModel.shouldMergeOnSwitch = (resolution == .merge)
                        await authViewModel.switchAccountWithPendingCredential()
                        showConflictSheet = false
                        dismiss()
                    }
                },
                onCancel: {
                    authViewModel.pendingCredential = nil
                    authViewModel.errorMessage = nil
                    showConflictSheet = false
                }
            )
        }
    }
    
    private func handleAppleSignIn() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let delegate = AppleSignInDelegate(
            onSuccess: { authorization in
                Task {
                    await authViewModel.linkWithApple(authorization: authorization)
                    if authViewModel.isSignedIn && !authViewModel.isAnonymous {
                        dismiss()
                    }
                }
            },
            onError: { error in
                if (error as NSError).code != 1000 {
                    print("DEBUG: Apple linking error: \(error)")
                    authViewModel.errorMessage = error.localizedDescription
                }
            }
        )
        let presentationContext = AppleSignInPresentationContextProvider()
        
        appleSignInDelegate = delegate
        appleSignInPresentationContext = presentationContext
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = presentationContext
        authorizationController.performRequests()
    }
}

// MARK: - Reusable Apple Sign-In Helpers for linking (Local to avoid conflicts)
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let onSuccess: (ASAuthorization) -> Void
    let onError: (Error) -> Void
    
    init(onSuccess: @escaping (ASAuthorization) -> Void, onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onSuccess(authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onError(error)
    }
}

private class AppleSignInPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}

// MARK: - Custom Conflict Resolution Sheet
enum ConflictResolutionOption {
    case merge
    case overwrite
}

struct ConflictResolutionView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedOption: ConflictResolutionOption = .merge
    
    let onResolve: (ConflictResolutionOption) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Constants.Spacing.extraLarge) {
                // Warning Header
                VStack(spacing: Constants.Spacing.medium) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.warningAmber)
                        .padding(.top, 30)
                    
                    Text("Account Already Exists")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("This Google/Apple account is already linked to another LogCal account. Choose how you want to proceed:")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.Spacing.large)
                }
                
                // Selectable Cards
                VStack(spacing: Constants.Spacing.large) {
                    // Option 1: Merge
                    Button(action: {
                        selectedOption = .merge
                    }) {
                        HStack(alignment: .top, spacing: Constants.Spacing.large) {
                            Image(systemName: selectedOption == .merge ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(selectedOption == .merge ? Theme.primaryGreen : Theme.mutedText(colorScheme: colorScheme))
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Option 1: Merge guest data (Default)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Your local guest meals will be uploaded and combined with the existing account's data. Nothing is deleted.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.secondaryText)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(Constants.Spacing.large)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedOption == .merge ? Theme.primaryGreen : Theme.cardBorder(colorScheme: colorScheme), lineWidth: selectedOption == .merge ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Option 2: Overwrite
                    Button(action: {
                        selectedOption = .overwrite
                    }) {
                        HStack(alignment: .top, spacing: Constants.Spacing.large) {
                            Image(systemName: selectedOption == .overwrite ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(selectedOption == .overwrite ? Theme.primaryGreen : Theme.mutedText(colorScheme: colorScheme))
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Option 2: Overwrite guest data")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Logs from your guest session will be discarded. You will sign into the existing account and load its cloud data.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.secondaryText)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(Constants.Spacing.large)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedOption == .overwrite ? Theme.primaryGreen : Theme.cardBorder(colorScheme: colorScheme), lineWidth: selectedOption == .overwrite ? 2 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, Constants.Spacing.extraLarge)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: Constants.Spacing.regular) {
                    Button(action: {
                        onResolve(selectedOption)
                    }) {
                        HStack {
                            Spacer()
                            Text("Okay")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .background(Theme.primaryGreen)
                        .cornerRadius(25)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    
                    Button(action: {
                        onCancel()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 20)
            }
            .background(Theme.backgroundColor(colorScheme: colorScheme))
            .navigationBarHidden(true)
        }
    }
}
