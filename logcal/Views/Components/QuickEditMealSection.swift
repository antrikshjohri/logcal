//
//  QuickEditMealSection.swift
//  logcal
//

import SwiftUI

struct QuickEditMealSection: View {
    @Binding var prompt: String
    var isLoading: Bool
    var errorMessage: String?
    var onApply: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
            HStack(alignment: .center, spacing: Constants.Spacing.medium) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.06))
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick edit")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("Did we get something wrong? Edit the logged meal.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            TextField("What should we change?", text: $prompt, axis: .vertical)
                .lineLimit(2...5)
                .padding(Constants.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius, style: .continuous)
                        .fill(Theme.cardBackground(colorScheme: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius, style: .continuous)
                        .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
                )
                .disabled(isLoading)

            Button(action: {
                print("DEBUG: [QuickEditMealSection] Apply tapped promptLen=\(prompt.count)")
                onApply()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .padding(.trailing, 6)
                    }
                    Text(isLoading ? "Updating…" : "Update the log")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.primary)
            .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(Constants.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius, style: .continuous)
                .fill(Theme.cardBackground(colorScheme: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius, style: .continuous)
                .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
        )
        .onAppear {
            print("DEBUG: [QuickEditMealSection] panel appeared")
        }
    }
}
