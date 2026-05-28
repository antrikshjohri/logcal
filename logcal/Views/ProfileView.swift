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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Spacing.extraLarge) {
                    Group {
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
                                
                                Divider()
                                    .background(Theme.cardBorder(colorScheme: colorScheme).opacity(0.5))
                                    .padding(.leading, 56)
                                
                                SettingsGroupButtonRow(
                                    icon: "paintpalette",
                                    iconColor: Theme.primaryGreen,
                                    title: "Theme",
                                    trailingValue: themeDisplayName
                                ) {
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
}

private struct SettingsGroupRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let trailingValue: String?
    
    init(icon: String, iconColor: Color = Theme.secondaryText, title: String, trailingValue: String? = nil) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.trailingValue = trailingValue
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.regular) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.primary)
            
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
    let iconColor: Color
    let title: String
    let trailingValue: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingsGroupRow(icon: icon, iconColor: iconColor, title: title, trailingValue: trailingValue)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
}
