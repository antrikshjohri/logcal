//
//  ProfileView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject private var toastManager: ToastManager
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("dailyGoal") private var dailyGoal: Double = 2000
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showThemeSelector = false
    @State private var showEditProfile = false
    @State private var showLinkSheet = false
    @State private var profileImage: UIImage?
    @State private var showWhatsAppSettings = false
    @State private var isWhatsAppLinked = false
    @State private var showFeedbackSheet = false
    private let firestoreService = FirestoreService()
    
    // User info
    private var userName: String {
        if authViewModel.isAnonymous {
            return "Guest User"
        }
        if let name = authViewModel.userName {
            return name
        } else if let email = Auth.auth().currentUser?.email {
            return String(email.split(separator: "@").first ?? "User")
        }
        return "User"
    }
    
    private var userEmail: String {
        if authViewModel.isAnonymous {
            return "Logs are saved locally"
        }
        return Auth.auth().currentUser?.email ?? "No email"
    }
    
    // Format goal for display
    private var formattedGoal: String {
        "\(Int(dailyGoal)) cal"
    }
    
    // Current theme display
    @AppStorage("appTheme") private var appThemeString: String = AppTheme.light.rawValue
    @AppStorage("hasSeenAppleHealthBadge") private var hasSeenAppleHealthBadge: Bool = false
    private var currentTheme: AppTheme {
        AppTheme(rawValue: appThemeString) ?? .system
    }
    
    private var themeDisplayName: String {
        switch currentTheme {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Spacing.extraLarge) {
                    Group {
                        if authViewModel.isAnonymous {
                            VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                                HStack(spacing: Constants.Spacing.regular) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.warningAmber)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Guest Session")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        Text("Your logs are saved only on this device. Sign in to back them up to the cloud.")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Theme.secondaryText)
                                    }
                                }
                                
                                Button(action: {
                                    AnalyticsService.trackProfileSignInToSyncTapped()
                                    showLinkSheet = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("Sign In to Sync")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .background(Theme.primaryGreen)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(Constants.Spacing.extraLarge)
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.warningAmber.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        }

                        // User Card
                        ProfileCard(
                            name: userName,
                            email: userEmail,
                            profileImage: profileImage,
                            isAnonymous: authViewModel.isAnonymous,
                            onEditProfile: {
                                AnalyticsService.trackProfileEditProfileTapped()
                                showEditProfile = true
                            }
                        )
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                        
                        // Account & Preferences Section
                        VStack(alignment: .leading, spacing: 6) {
                            settingsGroupHeader("ACCOUNT & PREFERENCES")
                            
                            VStack(spacing: 0) {
                                NavigationLink(destination: DailyGoalView()) {
                                    SettingsGroupRow(
                                        icon: "target",
                                        iconColor: Theme.primaryGreen,
                                        title: "Daily Goal",
                                        trailingValue: formattedGoal
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    AnalyticsService.trackProfileDailyGoalTapped()
                                })
                                
                                Divider()
                                    .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                    .padding(.leading, 56)
                                
                                NavigationLink(destination: SavedMealsView()) {
                                    SettingsGroupRow(
                                        icon: "bookmark.fill",
                                        iconColor: Theme.primaryGreen,
                                        title: "Favourite meals"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    AnalyticsService.trackProfileFavouriteMealsTapped()
                                })
                                
                                Divider()
                                    .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                    .padding(.leading, 56)
                                
                                SettingsGroupButtonRow(
                                    icon: "paintpalette",
                                    iconColor: Theme.primaryGreen,
                                    title: "Theme",
                                    trailingValue: themeDisplayName
                                ) {
                                    AnalyticsService.trackProfileThemeTapped()
                                    showThemeSelector = true
                                }
                                
                                Divider()
                                    .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                    .padding(.leading, 56)
                                
                                NavigationLink(destination: NotificationsSettingsView()) {
                                    SettingsGroupRow(
                                        icon: "bell.fill",
                                        iconColor: Theme.primaryGreen,
                                        title: "Meal Reminders"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    AnalyticsService.trackProfileMealRemindersTapped()
                                })
                                
                                Divider()
                            }
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        }
                        
                        // Integrations & Shortcuts Section
                        VStack(alignment: .leading, spacing: 6) {
                            settingsGroupHeader("INTEGRATIONS & SHORTCUTS")
                            
                            VStack(spacing: 0) {
                                NavigationLink(destination: AppleHealthSettingsView()) {
                                    SettingsGroupRow(
                                        icon: "heart.fill",
                                        iconColor: .red,
                                        title: "Apple Health",
                                        trailingValue: HealthKitService.shared.isAuthorized ? "Connected" : (HealthKitService.shared.isHealthKitSyncEnabled ? "Enabled" : "Not Connected"),
                                        badge: (!hasSeenAppleHealthBadge && !HealthKitService.shared.isAuthorized) ? "NEW" : nil
                                    )
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    hasSeenAppleHealthBadge = true
                                })
                                .buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                    .padding(.leading, 56)
                                
                                SettingsGroupButtonRow(
                                    icon: "WhatsAppIcon",
                                    isCustomIcon: true,
                                    iconColor: .clear,
                                    title: "Log using Whatsapp",
                                    trailingValue: isWhatsAppLinked ? "Linked" : "Not Linked"
                                ) {
                                    AnalyticsService.trackProfileLogWhatsAppTapped()
                                    showWhatsAppSettings = true
                                }
                            }
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        }
                        
                        // Support Section
                        VStack(alignment: .leading, spacing: 6) {
                            settingsGroupHeader("SUPPORT")
                            
                            VStack(spacing: 0) {
                                NavigationLink(destination: HelpFAQView()) {
                                    SettingsGroupRow(
                                        icon: "questionmark.circle",
                                        iconColor: Theme.primaryGreen,
                                        title: "Help & FAQ"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    AnalyticsService.trackProfileHelpFAQTapped()
                                })
                                
                                Divider()
                                    .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                    .padding(.leading, 56)
                                
                                SettingsGroupButtonRow(
                                    icon: "message",
                                    iconColor: Theme.primaryGreen,
                                    title: "Send Feedback"
                                ) {
                                    AnalyticsService.trackProfileSendFeedbackTapped()
                                    showFeedbackSheet = true
                                }
                            }
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        }
                        .padding(.bottom, Constants.Spacing.extraLarge)
                    }
                    .frame(maxWidth: horizontalSizeClass == .regular ? 650 : .infinity)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .background(Theme.backgroundColor(colorScheme: colorScheme))
            .sheet(isPresented: $showThemeSelector) {
                ThemeSelectorSheet()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackSheet()
            }
            .sheet(isPresented: $showLinkSheet) {
                LinkAccountView()
                    .environmentObject(authViewModel)
                    .environmentObject(toastManager)
            }
            .sheet(isPresented: $showWhatsAppSettings) {
                LinkWhatsAppView()
            }
            .onAppear {
                loadProfileImage()
                fetchWhatsAppStatus()
            }
            .onChange(of: showWhatsAppSettings) { oldValue, newValue in
                if oldValue && !newValue {
                    fetchWhatsAppStatus()
                }
            }
            .onChange(of: authViewModel.currentUser) { oldValue, newValue in
                loadProfileImage()
            }
            .onChange(of: authViewModel.userName) { oldValue, newValue in
                // Refresh when userName changes (e.g., after profile update)
            }
            .onChange(of: showEditProfile) { oldValue, newValue in
                // When EditProfile sheet is dismissed, refresh profile data
                if oldValue && !newValue {
                    // Sheet was dismissed - refresh user data
                    if let user = Auth.auth().currentUser {
                        Task {
                            try? await user.reload()
                            await MainActor.run {
                                authViewModel.updateUserName()
                                loadProfileImage()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func settingsGroupHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
            .padding(.horizontal, Constants.Spacing.extraLarge + 4)
    }
    
    private func loadProfileImage() {
        guard let photoURL = Auth.auth().currentUser?.photoURL else {
            profileImage = nil
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: photoURL)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        profileImage = image
                    }
                }
            } catch {
                print("DEBUG: Failed to load profile image: \(error)")
            }
        }
    }
    
    private func fetchWhatsAppStatus() {
        Task {
            do {
                let info = try await firestoreService.fetchWhatsAppLinkageInfo()
                await MainActor.run {
                    isWhatsAppLinked = (info.phoneNumber != nil)
                }
            } catch {
                print("DEBUG: Error checking WhatsApp status: \(error)")
            }
        }
    }
}

private struct SettingsGroupRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let isCustomIcon: Bool
    let iconColor: Color
    let title: String
    let trailingValue: String?
    let badge: String?
    
    init(icon: String, isCustomIcon: Bool = false, iconColor: Color = Theme.secondaryText, title: String, trailingValue: String? = nil, badge: String? = nil) {
        self.icon = icon
        self.isCustomIcon = isCustomIcon
        self.iconColor = iconColor
        self.title = title
        self.trailingValue = trailingValue
        self.badge = badge
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.regular) {
            if isCustomIcon {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .cornerRadius(4)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
            }
            
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.primary)
            
            if let badge = badge {
                Text(badge)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.primaryGreen)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            if let value = trailingValue {
                Text(value)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Theme.secondaryText)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.secondaryText)
        }
        .padding(Constants.Spacing.large)
        .contentShape(Rectangle())
    }
}

private struct SettingsGroupButtonRow: View {
    let icon: String
    let isCustomIcon: Bool
    let iconColor: Color
    let title: String
    let trailingValue: String?
    let action: () -> Void
    
    init(icon: String, isCustomIcon: Bool = false, iconColor: Color = Theme.secondaryText, title: String, trailingValue: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.isCustomIcon = isCustomIcon
        self.iconColor = iconColor
        self.title = title
        self.trailingValue = trailingValue
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            SettingsGroupRow(icon: icon, isCustomIcon: isCustomIcon, iconColor: iconColor, title: title, trailingValue: trailingValue)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
}
