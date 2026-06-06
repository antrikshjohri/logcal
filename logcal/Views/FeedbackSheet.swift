//
//  FeedbackSheet.swift
//  logcal
//

import SwiftUI
import FirebaseAuth

struct FeedbackSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toastManager: ToastManager
    
    private let firestoreService = FirestoreService()
    
    @State private var feedbackText = ""
    @State private var contactEmail = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    private let textLimit = 2000
    
    private var isSubmitDisabled: Bool {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Spacing.extraLarge) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Feedback")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        
                        Text("We would love to hear your thoughts, feature requests, or bugs you've encountered.")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.top, Constants.Spacing.extraLarge)
                    
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("YOUR MESSAGE")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .padding(.horizontal, 4)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $feedbackText)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(minHeight: 180)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.cardBackground(colorScheme: colorScheme))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                                )
                                .onChange(of: feedbackText) { _, newValue in
                                    if newValue.count > textLimit {
                                        feedbackText = String(newValue.prefix(textLimit))
                                    }
                                }
                            
                            if feedbackText.isEmpty {
                                Text("Write your feedback here...")
                                    .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Text("\(feedbackText.count)/\(textLimit)")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(Theme.quietText(colorScheme: colorScheme))
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("CONTACT EMAIL (OPTIONAL)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                            .padding(.horizontal, 4)
                        
                        TextField("Enter your email", text: $contactEmail)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(Constants.Spacing.regular)
                            .background(Theme.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.dangerRed)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Constants.Spacing.extraLarge)
                    }
                    
                    PrimaryButton(title: isLoading ? "Submitting..." : "Submit Feedback", isDisabled: isSubmitDisabled) {
                        Task {
                            await submitFeedback()
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.top, Constants.Spacing.medium)
                }
            }
            .background(Theme.backgroundColor(colorScheme: colorScheme))
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primaryGreen)
                }
            }
            .onAppear {
                AnalyticsService.trackViewOpened(viewName: "feedback_form")
                if let currentUser = Auth.auth().currentUser, let email = currentUser.email, !currentUser.isAnonymous {
                    contactEmail = email
                }
            }
        }
    }
    
    private func submitFeedback() async {
        isLoading = true
        errorMessage = nil
        
        let trimmedText = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try await firestoreService.submitFeedback(
                text: trimmedText,
                email: trimmedEmail.isEmpty ? nil : trimmedEmail
            )
            
            AnalyticsService.trackFeedbackSubmitted()
            
            toastManager.show(ToastMessage(
                title: "Feedback Sent",
                message: "Thank you for helping us improve LogCal!",
                type: .success
            ))
            
            dismiss()
        } catch {
            print("DEBUG: Failed to submit feedback: \(error)")
            errorMessage = "Failed to submit feedback: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

#Preview {
    FeedbackSheet()
        .environmentObject(ToastManager())
}
