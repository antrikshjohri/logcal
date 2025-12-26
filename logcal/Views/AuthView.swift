//
//  AuthView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: Constants.Spacing.extraLarge) {
                Spacer()
                
                // App logo/icon
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Constants.Colors.primaryBlue)
                    .padding(.bottom, Constants.Spacing.large)
                
                // Welcome text
                VStack(spacing: Constants.Spacing.medium) {
                    Text("Welcome to LogCal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to personalize your experience")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.secondaryGray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Constants.Spacing.extraLarge)
                
                // Sign-in buttons
                VStack(spacing: Constants.Spacing.regular) {
                    // Google Sign-In
                    Button(action: {
                        Task {
                            await authViewModel.signInWithGoogle()
                            if authViewModel.isSignedIn {
                                isPresented = false
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Continue with Google")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.26, green: 0.52, blue: 0.96)) // Google blue
                        .cornerRadius(Constants.Sizes.cornerRadius)
                    }
                    .disabled(authViewModel.isLoading)
                }
                .padding(.horizontal, Constants.Spacing.extraLarge)
                
                // Error message
                if let errorMessage = authViewModel.errorMessage {
                    ErrorBanner(
                        title: "Sign-In Error",
                        message: errorMessage,
                        type: .error
                    )
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                }
                
                // Loading indicator
                if authViewModel.isLoading {
                    ProgressView()
                        .padding()
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    AuthView(isPresented: .constant(true))
}

