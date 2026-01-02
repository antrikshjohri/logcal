//
//  ToastNotification.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import Combine

class ToastManager: ObservableObject {
    @Published var currentToast: ToastMessage?
    
    func show(_ message: ToastMessage) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentToast = message
        }
        
        // Auto-dismiss after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if self.currentToast?.id == message.id {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.currentToast = nil
                }
            }
        }
    }
    
    func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            currentToast = nil
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let type: ToastType
    
    enum ToastType {
        case error
        case warning
        case success
        
        var icon: String {
            switch self {
            case .error:
                return "exclamationmark.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .success:
                return "checkmark.circle.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .error:
                return Constants.Colors.primaryRed
            case .warning:
                return .orange
            case .success:
                return .green
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .error:
                return Color(.systemBackground)
            case .warning:
                return Color(.systemBackground)
            case .success:
                return Color(.systemBackground)
            }
        }
    }
}

struct ToastNotification: View {
    let toast: ToastMessage
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack(spacing: Constants.Spacing.regular) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(toast.type.iconColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(toast.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(toast.message)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(Constants.Spacing.regular)
        .background(toast.type.backgroundColor)
        .cornerRadius(Constants.Sizes.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Sizes.cornerRadius)
                .stroke(toast.type.iconColor.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, Constants.Spacing.regular)
        .padding(.top, Constants.Spacing.regular)
    }
}

struct ToastNotificationModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let toast = toastManager.currentToast {
                ToastNotification(toast: toast, isPresented: Binding(
                    get: { toastManager.currentToast != nil },
                    set: { if !$0 { toastManager.dismiss() } }
                ))
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .zIndex(1000)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastManager.currentToast?.id)
            }
        }
    }
}

extension View {
    func toastNotification(toastManager: ToastManager) -> some View {
        modifier(ToastNotificationModifier(toastManager: toastManager))
    }
}

#Preview {
    VStack(spacing: 16) {
        ToastNotification(
            toast: ToastMessage(
                title: "Error",
                message: "Failed to log meal. Please try again.",
                type: .error
            ),
            isPresented: .constant(true)
        )
        
        ToastNotification(
            toast: ToastMessage(
                title: "Warning",
                message: "Microphone permission denied",
                type: .warning
            ),
            isPresented: .constant(true)
        )
        
        ToastNotification(
            toast: ToastMessage(
                title: "Success",
                message: "Meal logged successfully!",
                type: .success
            ),
            isPresented: .constant(true)
        )
    }
    .padding()
}

