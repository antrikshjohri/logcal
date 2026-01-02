//
//  AuthView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

// Provider enum for authentication providers
enum AuthProvider {
    case apple
    case google
    case facebook  // Reserved for future
    case adobe      // Reserved for future
    
    var title: String {
        switch self {
        case .apple: return "Sign in with Apple"
        case .google: return "Sign in with Google"
        case .facebook: return "Sign in with Facebook"
        case .adobe: return "Sign in with Adobe"
        }
    }
}

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject private var toastManager: ToastManager
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    // Flag to show/hide Apple Sign-In button
    // Set to false to hide Apple Sign-In (e.g., if you don't have Apple Developer Program)
    // Set to true to show Apple Sign-In (requires: paid Apple Developer account, capability in Xcode, Firebase enabled)
    private let showAppleSignIn = true
    
    // Animation state for demo
    @State private var currentMealIndex = 0
    @State private var animationTimer: Timer?
    @State private var showMealText = false
    @State private var showArrow = false
    @State private var showCalories = false
    @State private var animationPhase: AnimationPhase = .mealText
    
    // Store Apple Sign-In delegates to prevent deallocation
    @State private var appleSignInDelegate: AppleSignInDelegate?
    @State private var appleSignInPresentationContext: AppleSignInPresentationContextProvider?
    
    enum AnimationPhase {
        case mealText
        case arrow
        case calories
        case fadeOut
    }
    
    // Sample meals for animation - global dishes
    private let demoMeals: [(text: String, calories: Int)] = [
        ("One bowl of grilled chicken salad and garlic bread", 520),
        ("A large burrito bowl with guacamole", 620),
        ("Butter chicken with 1 naan and rice", 680),
        ("Salmon teriyaki and rice", 580),
        ("One bowl of caesar salad with grilled chicken", 450),
        ("Two slices of margherita pizza", 290),
        ("One plate of dal makhani with roti", 480),
        ("Two slices of avocado toast with poached eggs", 420),
        ("1 bowl Fish and chips", 650),
        ("One plate of pad thai with vegetables", 520)
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
                            .background(caloriesCardBackground)
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
                        if showAppleSignIn {
                            AuthProviderButton(
                                provider: .apple,
                                isDisabled: authViewModel.isLoading
                            ) {
                                handleAppleSignIn()
                            }
                        }
                        
                        // Google Sign-In
                        AuthProviderButton(
                            provider: .google,
                            isDisabled: authViewModel.isLoading
                        ) {
                            Task {
                                // #region agent log
                                DebugLogger.log(location: "AuthView.swift:172", message: "Google sign-in button tapped", data: [:], hypothesisId: "C")
                                // #endregion
                                await authViewModel.signInWithGoogle()
                                // #region agent log
                                DebugLogger.log(location: "AuthView.swift:175", message: "After signInWithGoogle, checking isSignedIn", data: ["isSignedIn": authViewModel.isSignedIn, "userId": authViewModel.currentUser?.uid ?? "nil"], hypothesisId: "C")
                                // #endregion
                                if authViewModel.isSignedIn {
                                    // #region agent log
                                    DebugLogger.log(location: "AuthView.swift:177", message: "Setting isPresented to false", data: [:], hypothesisId: "C")
                                    // #endregion
                                    isPresented = false
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.bottom, Constants.Spacing.large)
                    
                    
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
        .onChange(of: authViewModel.errorMessage) { oldValue, newValue in
            if let message = newValue, message != oldValue {
                toastManager.show(ToastMessage(
                    title: "Sign-In Error",
                    message: message,
                    type: .error
                ))
            }
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
    
    // Calories card background - more visible in dark mode
    private var caloriesCardBackground: Color {
        colorScheme == .dark 
            ? Color.gray.opacity(0.25) // More visible in dark mode
            : Constants.Colors.primaryBackground // Light mode: subtle gray
    }
    
    private func handleAppleSignIn() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Create and store delegates to prevent deallocation
        let delegate = AppleSignInDelegate(
            onSuccess: { authorization in
                Task {
                    await authViewModel.handleAppleSignIn(authorization: authorization)
                    if authViewModel.isSignedIn {
                        isPresented = false
                    }
                }
            },
            onError: { error in
                // Error code 1000 is user cancellation - don't show error
                if (error as NSError).code != 1000 {
                    print("DEBUG: Apple sign-in error: \(error)")
                    authViewModel.errorMessage = error.localizedDescription
                } else {
                    print("DEBUG: Apple sign-in cancelled by user")
                }
            }
        )
        let presentationContext = AppleSignInPresentationContextProvider()
        
        // Store references to keep them alive
        appleSignInDelegate = delegate
        appleSignInPresentationContext = presentationContext
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = presentationContext
        authorizationController.performRequests()
    }
}

// MARK: - Apple Sign-In Helpers
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

// MARK: - Reusable Auth Provider Button Component
struct AuthProviderButton: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    let provider: AuthProvider
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                // Background and border
                RoundedRectangle(cornerRadius: 25) // Capsule: height/2
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(borderColor, lineWidth: 1)
                    )
                
                // Content - label visually centered, icon on left
                HStack {
                    // Icon - 18-20pt size, left aligned
                    providerIcon
                        .frame(width: 20, height: 20)
                    
                    // Spacer to push text toward center
                    Spacer()
                    
                    // Label - visually centered
                    Text(provider.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    // Spacer to balance icon on left
                    Spacer()
                    
                    // Invisible spacer matching icon width to balance layout
                    Color.clear
                        .frame(width: 20, height: 20)
                }
                .padding(.horizontal, 16) // Horizontal padding
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .opacity(isPressed ? 0.8 : 1.0)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .accessibilityLabel(provider.title)
        .accessibilityHint("Tap to sign in with \(provider.title.replacingOccurrences(of: "Sign in with ", with: ""))")
    }
    
    // MARK: - Theme Colors
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    private var borderColor: Color {
        colorScheme == .dark 
            ? Color.gray.opacity(0.3) // Dark gray border in dark mode
            : Color.gray.opacity(0.2)  // Light gray border in light mode
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    // MARK: - Provider Icons
    @ViewBuilder
    private var providerIcon: some View {
        switch provider {
        case .apple:
            // Apple icon - matches text color
            Image(systemName: "applelogo")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(textColor)
            
        case .google:
            // Google logo - full color, no tinting
            // Slightly larger to compensate for image padding and match Apple logo visual size
            Image("GoogleLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            
        case .facebook:
            // Placeholder for future
            Image(systemName: "f.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(textColor)
            
        case .adobe:
            // Placeholder for future
            Image(systemName: "a.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(textColor)
        }
    }
}

#Preview {
    AuthView(isPresented: .constant(true))
}
