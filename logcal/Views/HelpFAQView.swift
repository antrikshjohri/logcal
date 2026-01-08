//
//  HelpFAQView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct HelpFAQView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var expandedFAQs: Set<UUID> = []
    
    private let faqs: [FAQItem] = [
        FAQItem(
            question: "How accurate is the calorie estimation?",
            answer: "LogCal uses OpenAI's GPT-4 to analyze your meal descriptions and provide calorie estimates. While highly accurate, estimates may vary based on portion sizes and preparation methods. We recommend being as specific as possible in your descriptions."
        ),
        FAQItem(
            question: "Can I edit logged meals?",
            answer: "Yes! Navigate to the History screen, find the meal you want to edit, and tap on it to view details. You can then adjust the calorie count or delete the entry."
        ),
        FAQItem(
            question: "How do I change my daily calorie goal?",
            answer: "Go to Profile > Daily Goal, then use the slider to adjust your daily calorie target. Your new goal will be saved automatically."
        ),
        FAQItem(
            question: "Does LogCal work offline?",
            answer: "LogCal requires an internet connection to analyze meals using AI. However, you can view your previously logged meals offline."
        ),
        FAQItem(
            question: "Is my data private and secure?",
            answer: "Absolutely. We use industry-standard encryption to protect your data. Your meal logs and personal information are never shared with third parties."
        ),
        FAQItem(
            question: "How does the voice input work?",
            answer: "Tap the microphone icon when logging a meal to use voice input. Your device will convert speech to text, which is then analyzed by our AI to estimate calories."
        ),
        FAQItem(
            question: "What if the calorie estimate seems wrong?",
            answer: "You can manually adjust any calorie estimate after logging. We also recommend providing detailed descriptions (e.g., \"grilled chicken breast, 6 oz\" instead of just \"chicken\")."
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Description
                Text("Find answers to commonly asked questions about LogCal.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Constants.Spacing.extraLarge)
                    .padding(.top, Constants.Spacing.regular)
                    .padding(.bottom, Constants.Spacing.large)
                
                // FAQ List
                VStack(spacing: 0) {
                    ForEach(faqs) { faq in
                        FAQCard(
                            faq: faq,
                            isExpanded: expandedFAQs.contains(faq.id),
                            colorScheme: colorScheme
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedFAQs.contains(faq.id) {
                                    expandedFAQs.remove(faq.id)
                                } else {
                                    expandedFAQs.insert(faq.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Constants.Spacing.extraLarge)
            }
        }
        .background(Theme.backgroundColor(colorScheme: colorScheme))
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AnalyticsService.trackHelpFAQOpened()
        }
    }
}

struct FAQCard: View {
    let faq: FAQItem
    let isExpanded: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: Constants.Spacing.regular) {
                    // Question mark icon
                    ZStack {
                        Circle()
                            .fill(Theme.accentBlue.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "questionmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.accentBlue)
                    }
                    
                    // Question text
                    Text(faq.question)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Chevron icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.secondaryText)
                }
                .padding(Constants.Spacing.large)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Answer (expandable)
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .background(Theme.cardBorder(colorScheme: colorScheme))
                        .padding(.horizontal, Constants.Spacing.large)
                    
                    Text(faq.answer)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Theme.secondaryText)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, Constants.Spacing.large)
                        .padding(.top, Constants.Spacing.regular)
                        .padding(.bottom, Constants.Spacing.large)
                        .padding(.leading, 48) // Align with question text
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.cardBackground(colorScheme: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: Constants.Sizes.borderWidth)
        )
        .cornerRadius(Constants.Sizes.cornerRadius)
        .padding(.bottom, Constants.Spacing.regular)
    }
}

#Preview {
        NavigationView {
        HelpFAQView()
    }
}

