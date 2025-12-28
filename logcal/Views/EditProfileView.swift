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
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var countryList = CountryList()
    
    // User data
    @State private var fullName: String = ""
    @State private var userEmail: String = ""
    @AppStorage("userCountry") private var userCountryCode: String = ""
    @State private var profileImage: UIImage?
    @State private var selectedPhoto: PhotosPickerItem?
    
    // UI state
    @State private var isLoading = false
    @State private var showCountryPicker = false
    @State private var errorMessage: String?
    
    // Country picker search
    @State private var countrySearchText = ""
    
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
                            Button(action: {
                                // Photo picker will be triggered via PhotosPicker
                            }) {
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
                    PrimaryButton(title: "Save Changes") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(isLoading)
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
        }
    }
    
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        // Load name
        if let displayName = user.displayName {
            fullName = displayName
        } else if let email = user.email {
            fullName = String(email.split(separator: "@").first ?? "")
        }
        
        // Load email
        userEmail = user.email ?? ""
        
        // Load profile photo
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
            // Update profile photo if changed
            if let profileImage = profileImage {
                try await uploadProfilePhoto(image: profileImage, userId: user.uid)
            }
            
            // Update display name
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = fullName.isEmpty ? nil : fullName
            try await changeRequest.commitChanges()
            
            // Update AuthViewModel immediately
            await MainActor.run {
                authViewModel.updateUserName()
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
        
        // Use continuation to convert callback-based API to async/await
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            _ = photoRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        // Get download URL
        let downloadURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            photoRef.downloadURL { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(domain: "EditProfileView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]))
                }
            }
        }
        
        // Update user's photoURL
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.photoURL = downloadURL
        try await changeRequest?.commitChanges()
        
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
