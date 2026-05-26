//
//  QuickEditMealSection.swift
//  logcal
//

import SwiftUI
import Combine

@MainActor
final class QuickEditDictationController: ObservableObject {
    @Published var isListening = false
    @Published var isTranscribing = false
    @Published var errorMessage: String?

    private let speechService = SpeechRecognitionService()
    private var cancellables = Set<AnyCancellable>()
    var onText: ((String) -> Void)?

    init() {
        speechService.onTranscriptionResult = { [weak self] text in
            self?.onText?(text)
        }
        speechService.$isListening
            .assign(to: &$isListening)
        speechService.$isTranscribing
            .assign(to: &$isTranscribing)
        speechService.$errorMessage
            .assign(to: &$errorMessage)
    }

    func toggle() {
        if speechService.isTranscribing { return }
        Task {
            if speechService.isListening {
                AnalyticsService.trackSpeechRecognitionStopped()
                await speechService.stopListening()
            } else {
                AnalyticsService.trackSpeechRecognitionStarted()
                await speechService.startListening()
            }
        }
    }

    func cancel() {
        speechService.cancelListening()
    }
}

struct QuickEditMealSection: View {
    @Binding var prompt: String
    var isLoading: Bool
    var errorMessage: String?
    var onApply: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var dictation = QuickEditDictationController()

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
                    Text("Fix food description")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("Tell us what to change about what you ate.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .bottom, spacing: Constants.Spacing.small) {
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    TextField("Correct the food description", text: $prompt, axis: .vertical)
                        .lineLimit(2...5)
                        .disabled(isLoading || dictation.isListening || dictation.isTranscribing)

                    if dictation.isListening {
                        Text("Listening...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if dictation.isTranscribing {
                        HStack(spacing: Constants.Spacing.small) {
                            ProgressView()
                            Text("Transcribing...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if dictation.isListening {
                    Button {
                        dictation.cancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.red.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Cancel dictation")
                }

                Button {
                    dictation.toggle()
                } label: {
                    if dictation.isTranscribing {
                        ProgressView()
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: dictation.isListening ? "arrow.up" : "mic")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(dictation.isListening ? .white : Constants.Colors.primaryBlue)
                            .frame(width: 36, height: 36)
                            .background(dictation.isListening ? Constants.Colors.primaryBlue : Constants.Colors.micInactiveBackground)
                            .clipShape(Circle())
                    }
                }
                .disabled(isLoading || dictation.isTranscribing)
                .accessibilityLabel(dictation.isListening ? "Send dictation" : "Start dictation")
            }
            .padding(Constants.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius, style: .continuous)
                    .fill(Theme.cardBackground(colorScheme: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius, style: .continuous)
                    .stroke(Theme.cardBorder(colorScheme: colorScheme), lineWidth: 1)
            )
            Button(action: {
                print("DEBUG: [QuickEditMealSection] Apply tapped promptLen=\(prompt.count)")
                onApply()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .padding(.trailing, 6)
                    }
                    Text(isLoading ? "Updating..." : "Update description")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.primary)
            .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let errorMessage = errorMessage ?? dictation.errorMessage, !errorMessage.isEmpty {
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
            dictation.onText = { text in
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    prompt = trimmed
                } else {
                    prompt += " " + trimmed
                }
            }
            print("DEBUG: [QuickEditMealSection] panel appeared")
        }
    }
}
