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
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("dailyGoal") private var dailyGoal: Double = 2000
    @State private var showThemeSelector = false
    @State private var showEditProfile = false
    @State private var profileImage: UIImage?
    
    // User info
    private var userName: String {
        if let name = authViewModel.userName {
            return name
        } else if let email = Auth.auth().currentUser?.email {
            return String(email.split(separator: "@").first ?? "User")
        }
        return "User"
    }
    
    private var userEmail: String {
        Auth.auth().currentUser?.email ?? "No email"
    }
    
    // Format goal for display
    private var formattedGoal: String {
        "\(Int(dailyGoal)) cal"
    }
    
    // Current theme display
    @AppStorage("appTheme") private var appThemeString: String = AppTheme.system.rawValue
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
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.extraLarge) {
                    // Header
                    HStack {
                        Text("Profile")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.top, Constants.Spacing.regular)
                    
                    // User Card
                    ProfileCard(
                        name: userName,
                        email: userEmail,
                        profileImage: profileImage,
                        onEditProfile: {
                            showEditProfile = true
                        }
                    )
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    
                    // Goals & Progress Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                        Text("Goals & Progress")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        
                        NavigationLink(destination: DailyGoalView()) {
                            SettingsRowContent(
                                icon: "target",
                                iconColor: Theme.accentBlue,
                                title: "Daily Goal",
                                trailingValue: formattedGoal
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    }
                    
                    // Appearance Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                        Text("Appearance")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        
                        SettingsRow(
                            icon: "paintpalette",
                            iconColor: Theme.accentBlue,
                            title: "Theme",
                            trailingValue: themeDisplayName
                        ) {
                            showThemeSelector = true
                        }
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    }
                    
                    // Notifications Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                        Text("Notifications")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        
                        NavigationLink(destination: NotificationsSettingsView()) {
                            SettingsRowContent(
                                icon: "bell.fill",
                                iconColor: Theme.accentBlue,
                                title: "Meal Reminders"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    }
                    
                    // Support Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                        Text("Support")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.secondaryText)
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                        
                        NavigationLink(destination: HelpFAQView()) {
                            SettingsRowContent(
                                icon: "questionmark.circle",
                                iconColor: Theme.accentBlue,
                                title: "Help & FAQ"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, Constants.Spacing.extraLarge)
                    }
                    
                    .padding(.bottom, Constants.Spacing.extraLarge)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Theme.backgroundColor(colorScheme: colorScheme))
            .sheet(isPresented: $showThemeSelector) {
                ThemeSelectorSheet()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .onAppear {
                loadProfileImage()
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
}

#Preview {
    ProfileView()
}
