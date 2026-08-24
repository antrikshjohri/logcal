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
                        AnalyticsService.trackWhatsAppCloseTapped()
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
                AnalyticsService.trackWhatsAppUnlinkTapped()
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
            // WhatsApp Icon representation using our custom asset
            Image("WhatsAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .padding(.top, 16)

            VStack(spacing: 8) {
                Text("Log via WhatsApp")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                
                Text("Log your meals by texting our WhatsApp bot. We will automatically parse calories and macros using AI.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                    .multilineTextAlignment(.center)
            }
            
            // Visual Guide with the active linkage code (or a placeholder if empty)
            WhatsAppVisualGuideView(code: linkageCode.isEmpty ? "<code>" : linkageCode)
            
            if linkageCode.isEmpty {
                Button(action: {
                    AnalyticsService.trackWhatsAppLinkTapped()
                    Task {
                        await linkWithWhatsAppFlow()
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 18))
                        Text("Link with WhatsApp")
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
                    AnalyticsService.trackWhatsAppOpenWATapped()
                    openWhatsAppToLink(with: linkageCode)
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up.right.circle.fill")
                            .font(.system(size: 18))
                        Text("Open WhatsApp to Link")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Theme.primaryGreen)
                    .cornerRadius(12)
                }
                
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Code:")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                        
                        Text(linkageCode)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.primaryGreen)
                        
                        if let expiry = linkageExpiry {
                            Text("(\(formattedRemainingTime(from: expiry)))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.warningAmber)
                        }
                    }
                    
                    Button(action: {
                        AnalyticsService.trackWhatsAppCheckStatusTapped()
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
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.cardBackground(colorScheme: colorScheme).opacity(0.5))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                )
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
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
    
    private func linkWithWhatsAppFlow() async {
        isLoading = true
        errorMessage = nil
        
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let code = String((0..<6).map { _ in chars.randomElement()! })
        let expiry = Date().addingTimeInterval(15 * 60) // 15 mins expiry
        
        do {
            try await firestoreService.saveWhatsAppLinkageCode(code, expiry: expiry)
            AnalyticsService.trackWhatsAppLinkingStarted()
            linkageCode = code
            linkageExpiry = expiry
            isLoading = false
            
            // Open WhatsApp immediately after saving code
            openWhatsAppToLink(with: code)
        } catch {
            errorMessage = "Failed to start linking: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func unlinkWhatsApp() async {
        isLoading = true
        errorMessage = nil
        do {
            try await firestoreService.unlinkWhatsApp()
            AnalyticsService.trackWhatsAppUnlinked()
            linkedPhoneNumber = nil
            linkageCode = ""
            linkageExpiry = nil
        } catch {
            errorMessage = "Failed to unlink: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func openWhatsAppToLink(with code: String) {
        AnalyticsService.trackWhatsAppOpened()
        let msg = "Please link my LogCal account with code: \(code)"
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

// MARK: - WhatsApp Visual Guide View
struct WhatsAppVisualGuideView: View {
    let code: String
    @State private var isPulsing = false
    @State private var isBouncing = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WHAT TO DO IN WHATSAPP")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
            
            VStack(spacing: 0) {
                // Mock WhatsApp Navigation Header
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Circle()
                        .fill(Theme.primaryGreen)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("LogCal Bot")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 5, height: 5)
                            Text("online")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "video")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    Image(systemName: "phone")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                        .padding(.leading, 8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(colorScheme == .dark ? Color(red: 0.08, green: 0.11, blue: 0.10) : Color(red: 0.96, green: 0.96, blue: 0.96))
                
                Divider()
                
                // Mock WhatsApp Chat Background Area (Empty chat area)
                VStack(spacing: 12) {
                    Spacer()
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(colorScheme == .dark ? Color(red: 0.04, green: 0.06, blue: 0.05) : Color(red: 0.90, green: 0.88, blue: 0.84))
                
                Divider()
                
                // Mock Input Bar with Pulsing Send Button
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        Text("Please link my LogCal account with code: \(code)")
                            .font(.system(size: 11))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(colorScheme == .dark ? Color(red: 0.10, green: 0.12, blue: 0.11) : Color.white)
                    .cornerRadius(16)
                    
                    // Pulsing Send Button
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 38, height: 38)
                            .scaleEffect(isPulsing ? 1.5 : 1.0)
                            .opacity(isPulsing ? 0.0 : 1.0)
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(45))
                            .offset(x: -1, y: 0)
                    }
                    .overlay(
                        // Bouncing Pointer Icon
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0.5, y: 0.5)
                            .offset(x: -12, y: isBouncing ? 12 : 20)
                    )
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(colorScheme == .dark ? Color(red: 0.08, green: 0.11, blue: 0.10) : Color(red: 0.96, green: 0.96, blue: 0.96))
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
            )
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
                withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isBouncing = true
                }
            }
            
            Text("Once WhatsApp opens, the text will be automatically filled for you. Simply tap the green Send button to finish connecting!")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                .padding(.horizontal, 4)
        }
        .padding()
        .background(Theme.cardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
        )
    }
}

#Preview {
    LinkWhatsAppView()
}

