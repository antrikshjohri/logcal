//
//  EditProfileView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct EditProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var countryList = CountryList()
    
    // User data
    @State private var fullName: String = ""
    @State private var userEmail: String = ""
    @AppStorage("userCountry") private var userCountryCode: String = ""
    @State private var profileImage: UIImage?
    @State private var selectedPhoto: PhotosPickerItem?
    
    // Original values to track changes
    @State private var originalFullName: String = ""
    @State private var originalCountryCode: String = ""
    @State private var originalPhotoURL: URL?
    @State private var hasPhotoChanged: Bool = false
    
    // UI state
    @State private var isLoading = false
    @State private var showCountryPicker = false
    @State private var errorMessage: String?
    @State private var showDeleteAccountConfirmation = false
    @State private var showDeleteAccountError = false
    @State private var isDeletingAccount = false
    
    // Country picker search
    @State private var countrySearchText = ""
    
    // Computed property to check if any changes were made
    private var hasChanges: Bool {
        let nameChanged = fullName != originalFullName
        let countryChanged = userCountryCode != originalCountryCode
        return nameChanged || countryChanged || hasPhotoChanged
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.extraLarge) {
                    // Profile Photo Section
                    VStack(spacing: Constants.Spacing.regular) {
                        ZStack(alignment: .bottomTrailing) {
                            // Profile photo or placeholder
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Theme.accentBlue)
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Camera icon button
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.cardBackground(colorScheme: colorScheme))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 2)
                                )
                            }
                            .offset(x: 0, y: 0)
                        }
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text("Change Profile Photo")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.accentBlue)
                        }
                    }
                    .padding(.top, Constants.Spacing.extraLarge)
                    
                    // Full Name Field
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Full Name")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("Enter your name", text: $fullName)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                            
                            Image(systemName: "person")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.secondaryText)
                        }
                        .padding(Constants.Spacing.regular)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                        )
                        .cornerRadius(Constants.Sizes.cornerRadius)
                    }
                    
                    // Email Field (Read-only)
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Email Address")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("Email", text: .constant(userEmail))
                                .font(.system(size: 17))
                                .foregroundColor(Theme.secondaryText)
                                .disabled(true)
                            
                            Image(systemName: "envelope")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.secondaryText)
                        }
                        .padding(Constants.Spacing.regular)
                        .background(Theme.cardBackground(colorScheme: colorScheme).opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                        )
                        .cornerRadius(Constants.Sizes.cornerRadius)
                        
                        Text("Email cannot be changed")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Theme.secondaryText)
                    }
                    
                    // Country Field
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Country")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            showCountryPicker = true
                        }) {
                            HStack {
                                Text(userCountryCode.isEmpty ? "e.g., United States, India, UK" : (countryList.countryName(for: userCountryCode) ?? ""))
                                    .font(.system(size: 17))
                                    .foregroundColor(userCountryCode.isEmpty ? Theme.secondaryText : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Image(systemName: "globe")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.secondaryText)
                            }
                            .padding(Constants.Spacing.regular)
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
                            )
                            .cornerRadius(Constants.Sizes.cornerRadius)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("Providing your country helps us better identify regional meals and portion sizes")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Theme.secondaryText)
                    }
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Save Button
                    PrimaryButton(title: "Save Changes", isDisabled: isLoading || !hasChanges) {
                        Task {
                            await saveChanges()
                        }
                    }
                    
                    // Divider
                    Divider()
                        .padding(.vertical, Constants.Spacing.regular)
                    
                    // Sign Out Button
                    Button(action: {
                        authViewModel.signOut()
                        dismiss()
                    }) {
                        HStack(spacing: Constants.Spacing.regular) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .medium))
                            Text("Sign Out")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(25)
                    }
                    
                    // Delete Account Button
                    Button(action: {
                        showDeleteAccountConfirmation = true
                    }) {
                        Text("Delete Account")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, Constants.Spacing.extraLarge)
                }
                .padding(.horizontal, Constants.Spacing.extraLarge)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.backgroundColor(colorScheme: colorScheme))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerView(
                    selectedCountryCode: $userCountryCode,
                    countryList: countryList,
                    isPresented: $showCountryPicker
                )
            }
            .onAppear {
                loadUserData()
            }
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let newValue = newValue {
                        await loadPhoto(from: newValue)
                    }
                }
            }
            .alert("Delete Account", isPresented: $showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        isDeletingAccount = true
                        do {
                            try await authViewModel.deleteAccount()
                            // Account deletion will automatically sign out the user
                            // The app will navigate to auth view automatically
                            dismiss()
                        } catch {
                            print("DEBUG: Account deletion failed: \(error)")
                            isDeletingAccount = false
                            // Show error alert
                            showDeleteAccountError = true
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone. All your meal data, goals, and account information will be permanently deleted.")
            }
            .alert("Error", isPresented: $showDeleteAccountError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authViewModel.errorMessage ?? "Failed to delete account. Please try again.")
            }
            .overlay {
                if isDeletingAccount {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Deleting account...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        // Load name
        if let displayName = user.displayName {
            fullName = displayName
            originalFullName = displayName
        } else if let email = user.email {
            let nameFromEmail = String(email.split(separator: "@").first ?? "")
            fullName = nameFromEmail
            originalFullName = nameFromEmail
        }
        
        // Load email
        userEmail = user.email ?? ""
        
        // Load original country code
        originalCountryCode = userCountryCode
        
        // Load profile photo and store original URL
        originalPhotoURL = user.photoURL
        hasPhotoChanged = false
        if let photoURL = user.photoURL {
            Task {
                await loadProfilePhoto(from: photoURL)
            }
        }
    }
    
    private func loadProfilePhoto(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    profileImage = image
                }
            }
        } catch {
            print("DEBUG: Failed to load profile photo: \(error)")
        }
    }
    
    private func loadPhoto(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }
        
        await MainActor.run {
            profileImage = image
            hasPhotoChanged = true // Mark that photo was changed
        }
    }
    
    private func saveChanges() async {
        isLoading = true
        errorMessage = nil
        
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User not signed in"
            isLoading = false
            return
        }
        
        do {
            // Update profile photo only if it was changed
            if hasPhotoChanged, let profileImage = profileImage {
                try await uploadProfilePhoto(image: profileImage, userId: user.uid)
            }
            
            // Update display name only if it changed
            if fullName != originalFullName {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = fullName.isEmpty ? nil : fullName
                try await changeRequest.commitChanges()
                
                // Reload the user to get updated profile data
                // This ensures the auth state listener in AuthViewModel picks up the change
                try? await user.reload()
                
                // Update AuthViewModel immediately
                await MainActor.run {
                    authViewModel.updateUserName()
                    // Trigger refresh in other views by updating AppStorage
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "profileUpdated")
                }
            }
            
            print("DEBUG: Profile updated successfully")
            isLoading = false
            dismiss()
        } catch {
            print("DEBUG: Failed to update profile: \(error)")
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func uploadProfilePhoto(image: UIImage, userId: String) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "EditProfileView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let storage = Storage.storage()
        let photoRef = storage.reference().child("users/\(userId)/profile.jpg")
        
        // Upload image with metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("DEBUG: Starting profile photo upload...")
        
        // Upload the image - this will create the file if it doesn't exist, or overwrite if it does
        // Use continuation to convert callback-based API to async/await
        // Wait for the upload to fully complete before proceeding
        let uploadMetadata = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata?, Error>) in
            let uploadTask = photoRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    print("DEBUG: Upload error: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("DEBUG: Upload callback received, metadata: \(metadata?.path ?? "nil")")
                    continuation.resume(returning: metadata)
                }
            }
            
            // Also observe the upload task state to ensure it's fully complete
            uploadTask.observe(.success) { snapshot in
                print("DEBUG: Upload task completed successfully")
            }
            
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    print("DEBUG: Upload task failed: \(error)")
                }
            }
        }
        
        print("DEBUG: Upload finished, metadata received: \(uploadMetadata?.path ?? "nil")")
        
        // Wait a moment for the file to be fully indexed in Firebase Storage
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Get download URL with retry logic
        var downloadURL: URL?
        var lastError: Error?
        
        print("DEBUG: Fetching download URL with retry logic...")
        
        // Try up to 5 times with increasing delays
            for attempt in 1...5 {
                do {
                    downloadURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                        photoRef.downloadURL { url, error in
                            if let error = error {
                                print("DEBUG: downloadURL attempt \(attempt) failed: \(error.localizedDescription)")
                                continuation.resume(throwing: error)
                            } else if let url = url {
                                print("DEBUG: downloadURL attempt \(attempt) succeeded: \(url.absoluteString)")
                                continuation.resume(returning: url)
                            } else {
                                continuation.resume(throwing: NSError(domain: "EditProfileView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]))
                            }
                        }
                    }
                    break // Success, exit retry loop
                } catch {
                    lastError = error
                    print("DEBUG: downloadURL attempt \(attempt) exception: \(error.localizedDescription)")
                    if attempt < 5 {
                        // Wait longer before retry: 0.5s, 1s, 1.5s, 2s
                        let delay = UInt64(attempt * 500_000_000)
                        print("DEBUG: Waiting \(Double(delay) / 1_000_000_000) seconds before retry...")
                        try? await Task.sleep(nanoseconds: delay)
                    }
                }
            }
        
        guard let url = downloadURL else {
            let errorMsg = lastError?.localizedDescription ?? "Unknown error"
            print("DEBUG: Failed to get download URL after all retries: \(errorMsg)")
            throw lastError ?? NSError(domain: "EditProfileView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL after retries: \(errorMsg)"])
        }
        
        print("DEBUG: Got download URL: \(url)")
        
        // Update user's photoURL
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "EditProfileView", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.photoURL = url
        try await changeRequest.commitChanges()
        
        print("DEBUG: Updated user photoURL in Firebase Auth")
        
        // Reload user to ensure changes are reflected
        try? await user.reload()
        
        print("DEBUG: Profile photo uploaded successfully")
    }
}

// Country Picker View
struct CountryPickerView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedCountryCode: String
    @ObservedObject var countryList: CountryList
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return countryList.countries
        }
        return countryList.countries.filter { country in
            country.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.secondaryText)
                    
                    TextField("Search countries", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(Constants.Spacing.regular)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .cornerRadius(Constants.Sizes.cornerRadius)
                .padding(.horizontal, Constants.Spacing.extraLarge)
                .padding(.top, Constants.Spacing.regular)
                
                // Country list
                List(filteredCountries) { country in
                    Button(action: {
                        selectedCountryCode = country.id
                        isPresented = false
                    }) {
                        HStack {
                            Text(country.name)
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if country.id == selectedCountryCode {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.accentBlue)
                            }
                        }
                        .padding(.vertical, Constants.Spacing.small)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .background(Theme.backgroundColor(colorScheme: colorScheme))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
}
