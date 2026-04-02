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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick fix")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text("Something wrong? Describe the fix (e.g. “brown rice, not white” or “two eggs, not one”).")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("What should change?", text: $prompt, axis: .vertical)
                .lineLimit(2...5)
                .textFieldStyle(.roundedBorder)
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
                    Text(isLoading ? "Updating…" : "Update estimate")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.Colors.primaryBlue)
            .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.top, 4)
    }
}
