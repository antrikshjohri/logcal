//
//  PendingMealsTrayView.swift
//  logcal
//

import SwiftUI

struct PendingMealsTrayView: View {
    @ObservedObject var viewModel: LogViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if !viewModel.pendingLogs.isEmpty {
            VStack(spacing: 10) {
                ForEach(viewModel.pendingLogs) { pending in
                    PendingMealCard(
                        pending: pending,
                        onRetry: { viewModel.retryPendingMeal(id: pending.id) },
                        onDismiss: { viewModel.removePendingMeal(id: pending.id) }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    ))
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct PendingMealCard: View {
    let pending: PendingMealLog
    let onRetry: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing = false

    private func mealTypeIcon(for type: String) -> String {
        switch type.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.stars.fill"
        default: return "leaf.fill"
        }
    }

    private func isFailedStatus(_ status: PendingLogStatus) -> Bool {
        if case .failed = status { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                // Status icon or spinner
                switch pending.status {
                case .processing:
                    ProgressView()
                        .scaleEffect(0.85)
                        .frame(width: 20, height: 20)
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.primaryGreen)
                case .failed:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.warningAmber)
                }

                // Food text and meal type badge
                VStack(alignment: .leading, spacing: 3) {
                    Text(pending.displayText)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        HStack(spacing: 3) {
                            Image(systemName: mealTypeIcon(for: pending.mealType.rawValue))
                                .font(.system(size: 8, weight: .bold))
                            Text(pending.mealType.rawValue.capitalized)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.softAccentBackground(colorScheme: colorScheme))
                        .foregroundColor(Theme.primaryGreen)
                        .cornerRadius(4)

                        switch pending.status {
                        case .processing:
                            Text("Estimating macros...")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                .opacity(isPulsing ? 0.4 : 1.0)
                        case .completed(let response, _):
                            Text("\(Int(response.totalCalories)) cal")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.primaryGreen)
                        case .failed(let error):
                            Text(error)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.warningAmber)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Actions for failed or dismiss
                switch pending.status {
                case .failed:
                    HStack(spacing: 6) {
                        Button(action: onRetry) {
                            Text("Retry")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.primaryGreen)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.mutedText(colorScheme: colorScheme))
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                    }
                case .completed:
                    EmptyView()
                case .processing:
                    EmptyView()
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.cardBackground(colorScheme: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFailedStatus(pending.status) 
                    ? Theme.warningAmber.opacity(0.4) 
                    : Theme.cardBorder(colorScheme: colorScheme),
                    lineWidth: 1
                )
        )
        .shadow(color: Theme.shadowColor(colorScheme: colorScheme).opacity(0.3), radius: 4, x: 0, y: 2)
        .onAppear {
            if pending.status == .processing {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
}
