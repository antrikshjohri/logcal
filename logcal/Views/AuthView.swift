//
//  AuthView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Binding var isPresented: Bool
    
    // Animation state for demo
    @State private var currentMealIndex = 0
    @State private var animationTimer: Timer?
    @State private var showMealText = false
    @State private var showArrow = false
    @State private var showCalories = false
    @State private var animationPhase: AnimationPhase = .mealText
    
    enum AnimationPhase {
        case mealText
        case arrow
        case calories
        case fadeOut
    }
    
    // Sample meals for animation - global dishes
    private let demoMeals: [(text: String, calories: Int)] = [
        ("Grilled chicken salad and garlic bread", 520),
        ("Beef burrito bowl with guacamole", 620),
        ("Pasta carbonara with parmesan", 680),
        ("Salmon teriyaki with rice", 580),
        ("Caesar salad with grilled chicken", 450),
        ("Margherita pizza slice", 290),
        ("Sushi platter with miso soup", 480),
        ("Avocado toast with poached eggs", 420),
        ("Fish and chips", 650),
        ("Pad Thai with vegetables", 520)
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Top spacing
                    Spacer()
                        .frame(height: 60)
                    
                    // Welcome heading
                    VStack(spacing: Constants.Spacing.medium) {
                        Text("Welcome to LogCal")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Speak to track calories")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(Constants.Colors.secondaryGray)
                    }
                    .padding(.bottom, Constants.Spacing.large) // Reduced from extraLarge * 2
                    
                    // Visual demo section - fixed height to prevent layout shifts
                    VStack(spacing: Constants.Spacing.large) {
                        // Microphone icon
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Constants.Colors.primaryBlue)
                        
                        // Fixed height container for meal text to prevent layout shifts
                        VStack {
                            Text("\"\(demoMeals[currentMealIndex].text)\"")
                                .font(.system(size: 17, weight: .medium, design: .default))
                                .italic()
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Constants.Spacing.extraLarge)
                                .opacity(showMealText ? 1 : 0)
                                .animation(.easeInOut(duration: 0.4), value: showMealText)
                        }
                        .frame(height: 50) // Fixed height for meal text
                        
                        // Fixed height container for arrow
                        VStack {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 20))
                                .foregroundColor(Constants.Colors.secondaryGray)
                                .padding(.vertical, Constants.Spacing.small)
                                .opacity(showArrow ? 1 : 0)
                                .animation(.easeInOut(duration: 0.4), value: showArrow)
                        }
                        .frame(height: 40) // Fixed height for arrow
                        
                        // Fixed height container for calories card
                        VStack {
                            VStack(alignment: .center, spacing: Constants.Spacing.small) {
                                Text("Logged")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Constants.Colors.secondaryGray)
                                
                                Text("\(demoMeals[currentMealIndex].calories) cal")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 200) // Fixed smaller width
                            .padding(Constants.Spacing.large)
                            .background(Constants.Colors.primaryBackground)
                            .cornerRadius(Constants.Sizes.largeCornerRadius)
                            .opacity(showCalories ? 1 : 0)
                            .animation(.easeInOut(duration: 0.4), value: showCalories)
                        }
                        .frame(height: 100) // Fixed height for calories card
                    }
                    .padding(.vertical, Constants.Spacing.extraLarge)
                    
                    // Sign in prompt
                    Text("Sign in to start logging")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Constants.Colors.secondaryGray)
                        .padding(.top, Constants.Spacing.extraLarge * 2)
                        .padding(.bottom, Constants.Spacing.large)
                    
                    // Sign-in buttons
                    VStack(spacing: Constants.Spacing.regular) {
                        // Apple Sign-In
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    Task {
                                        await authViewModel.handleAppleSignIn(authorization: authorization)
                                        if authViewModel.isSignedIn {
                                            isPresented = false
                                        }
                                    }
                                case .failure(let error):
                                    // Error code 1000 is user cancellation - don't show error
                                    if (error as NSError).code != 1000 {
                                        print("DEBUG: Apple sign-in error: \(error)")
                                        authViewModel.errorMessage = error.localizedDescription
                                    } else {
                                        print("DEBUG: Apple sign-in cancelled by user")
                                    }
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(Constants.Sizes.cornerRadius)
                        .disabled(authViewModel.isLoading)
                        
                        // Google Sign-In - following Google branding guidelines
                        GoogleSignInButton()
                            .disabled(authViewModel.isLoading)
                            .onTapGesture {
                                Task {
                                    await authViewModel.signInWithGoogle()
                                    if authViewModel.isSignedIn {
                                        isPresented = false
                                    }
                                }
                            }
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.bottom, Constants.Spacing.large)
                    
                    // Error message
                    if let errorMessage = authViewModel.errorMessage {
                        ErrorBanner(
                            title: "Sign-In Error",
                            message: errorMessage,
                            type: .error
                        )
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                        .padding(.bottom, Constants.Spacing.regular)
                    }
                    
                    // Loading indicator
                    if authViewModel.isLoading {
                        ProgressView()
                            .padding(.bottom, Constants.Spacing.regular)
                    }
                    
                    // Legal text
                    Text("By continuing, you agree to our Terms and Privacy Policy")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Constants.Colors.secondaryGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                        .padding(.top, Constants.Spacing.regular)
                        .padding(.bottom, Constants.Spacing.extraLarge)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        // Reset animation state
        showMealText = false
        showArrow = false
        showCalories = false
        animationPhase = .mealText
        
        // Start the animation sequence
        animateSequence()
    }
    
    private func animateSequence() {
        // Phase 1: Meal text fades in
        withAnimation(.easeIn(duration: 0.4)) {
            showMealText = true
        }
        
        // Phase 2: Arrow fades in after meal text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 0.4)) {
                showArrow = true
            }
            
            // Phase 3: Calories fade in after arrow
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.4)) {
                    showCalories = true
                }
                
                // Phase 4: All fade out together after showing calories
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showMealText = false
                        showArrow = false
                        showCalories = false
                    }
                    
                    // Move to next meal and repeat
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        currentMealIndex = (currentMealIndex + 1) % demoMeals.count
                        animateSequence()
                    }
                }
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

// Google Sign-In Button following Google branding guidelines
// Reference: https://developers.google.com/identity/branding-guidelines
struct GoogleSignInButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Google "G" logo - colorful Google logo on white background
            // According to guidelines: logo must be standard color on white background
            ZStack {
                // White background for Google logo (required by guidelines)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                
                // Google logo image asset
                Image("GoogleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            .frame(width: 20, height: 20)
            .padding(.leading, 4) // 12px left padding per iOS guidelines
            
            Text("Sign in with Google")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(colorScheme == .dark ? Color(red: 0.89, green: 0.89, blue: 0.89) : Color(red: 0.12, green: 0.12, blue: 0.12))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            colorScheme == .dark 
                ? Color(red: 0.075, green: 0.075, blue: 0.078) // Dark theme: #131314
                : Color.white // Light theme: #FFFFFF
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .stroke(
                    colorScheme == .dark 
                        ? Color(red: 0.56, green: 0.57, blue: 0.56) // Dark theme border: #8E918F
                        : Color(red: 0.45, green: 0.47, blue: 0.46), // Light theme border: #747775
                    lineWidth: 1
                )
        )
        .cornerRadius(Constants.Sizes.cornerRadius)
    }
}

#Preview {
    AuthView(isPresented: .constant(true))
}
