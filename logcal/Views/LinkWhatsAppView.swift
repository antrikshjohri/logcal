//
//  LinkWhatsAppView.swift
//  logcal
//
//  Created by Antriksh Johri on 2026-06-06.
//

import SwiftUI
import FirebaseAuth

struct LinkWhatsAppView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    private let firestoreService = FirestoreService()
    
    @State private var linkageCode: String = ""
    @State private var linkageExpiry: Date? = nil
    @State private var linkedPhoneNumber: String? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // We observe active app phases so if they go to WhatsApp and come back, we check automatically
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundColor(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading...")
                        .tint(Theme.primaryGreen)
                } else {
                    ScrollView {
                        VStack(spacing: Constants.Spacing.extraLarge) {
                            if let phoneNumber = linkedPhoneNumber {
                                linkedStateView(phoneNumber: phoneNumber)
                            } else {
                                unlinkedStateView
                            }
                        }
                        .padding(Constants.Spacing.extraLarge)
                    }
                }
            }
            .navigationTitle("WhatsApp Logging")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.primaryGreen)
                }
            }
            .task {
                await loadWhatsAppStatus()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await loadWhatsAppStatus()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func linkedStateView(phoneNumber: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Theme.primaryGreen)
                .padding(.top, 16)
            
            VStack(spacing: 8) {
                Text("WhatsApp Linked!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                
                Text("Your LogCal account is successfully connected to WhatsApp.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Theme.primaryGreen)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected Number")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        Text("+\(phoneNumber)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                )
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await unlinkWhatsApp()
                }
            }) {
                HStack {
                    Spacer()
                    Image(systemName: "link.badge.plus")
                    Text("Unlink Account")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .padding(.vertical, 14)
                .foregroundColor(.red)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    @ViewBuilder
    private var unlinkedStateView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Log via WhatsApp")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                
                Text("Log your meals by texting our WhatsApp bot. We will automatically parse calories and macros using AI.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                stepRow(number: "1", text: "Generate a secure, single-use linkage code below.")
                stepRow(number: "2", text: "Tap the connect button to open WhatsApp chat with our bot.")
                stepRow(number: "3", text: "Send the prefilled code message. Your account will link instantly!")
            }
            .padding()
            .background(Theme.cardBackground(colorScheme: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
            )
            
            if !linkageCode.isEmpty {
                VStack(spacing: 8) {
                    Text("YOUR LINKING CODE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    
                    Text(linkageCode)
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundColor(Theme.primaryGreen)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                        .background(Theme.softAccentBackground(colorScheme: colorScheme))
                        .cornerRadius(12)
                    
                    if let expiry = linkageExpiry {
                        Text("Expires in \(formattedRemainingTime(from: expiry))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.warningAmber)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.cardBackground(colorScheme: colorScheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                )
                
                Button(action: openWhatsAppToLink) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 18))
                        Text("Open WhatsApp & Link")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Theme.primaryGreen)
                    .cornerRadius(12)
                }
            } else {
                Button(action: {
                    Task {
                        await generateNewLinkageCode()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Generate Linking Code")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Theme.primaryGreen)
                    .cornerRadius(12)
                }
            }
            
            if !linkageCode.isEmpty {
                Button(action: {
                    Task {
                        await loadWhatsAppStatus()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Check Linkage Status")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Theme.primaryGreen)
                }
                .padding(.top, 8)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    @ViewBuilder
    private func stepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Theme.primaryGreen)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
        }
    }
    
    private func loadWhatsAppStatus() async {
        errorMessage = nil
        do {
            let info = try await firestoreService.fetchWhatsAppLinkageInfo()
            linkedPhoneNumber = info.phoneNumber
            
            // If the code from Firestore hasn't expired yet, keep it loaded
            if let expiry = info.linkageExpiry, expiry > Date() {
                linkageCode = info.linkageCode ?? ""
                linkageExpiry = expiry
            } else {
                linkageCode = ""
                linkageExpiry = nil
            }
        } catch {
            errorMessage = "Failed to load status: \(error.localizedDescription)"
        }
    }
    
    private func generateNewLinkageCode() async {
        isLoading = true
        errorMessage = nil
        
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let code = String((0..<6).map { _ in chars.randomElement()! })
        let expiry = Date().addingTimeInterval(15 * 60) // 15 mins expiry
        
        do {
            try await firestoreService.saveWhatsAppLinkageCode(code, expiry: expiry)
            linkageCode = code
            linkageExpiry = expiry
        } catch {
            errorMessage = "Failed to generate code: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func unlinkWhatsApp() async {
        isLoading = true
        errorMessage = nil
        do {
            try await firestoreService.unlinkWhatsApp()
            linkedPhoneNumber = nil
            linkageCode = ""
            linkageExpiry = nil
        } catch {
            errorMessage = "Failed to unlink: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func openWhatsAppToLink() {
        let msg = "link \(linkageCode)"
        let encodedMsg = msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let waUrlString = "https://wa.me/\(Constants.WhatsApp.botPhoneNumber)?text=\(encodedMsg)"
        
        if let url = URL(string: waUrlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func formattedRemainingTime(from date: Date) -> String {
        let remaining = date.timeIntervalSince(Date())
        if remaining <= 0 { return "Expired" }
        let mins = Int(remaining) / 60
        let secs = Int(remaining) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    LinkWhatsAppView()
}
