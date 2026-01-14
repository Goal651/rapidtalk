//
//  ToastNotification.swift
//  vynqtalk
//
//  Toast notification component with auto-dismiss and swipe-to-dismiss
//

import SwiftUI

struct ToastNotification: View {
    
    // MARK: - Notification Type
    
    enum NotificationType {
        case success
        case error
        case info
        case warning
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "xmark.circle.fill"
            case .info:
                return "info.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success:
                return AppTheme.AccentColors.success
            case .error:
                return AppTheme.AccentColors.error
            case .info:
                return AppTheme.AccentColors.primary
            case .warning:
                return AppTheme.AccentColors.warning
            }
        }
    }
    
    // MARK: - Properties
    
    let message: String
    let type: NotificationType
    var duration: Double = 3.0
    var onDismiss: (() -> Void)? = nil
    
    // MARK: - State
    
    @State private var offset: CGFloat = -100
    @State private var dragOffset: CGFloat = 0
    @State private var opacity: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Icon
            Image(systemName: type.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(type.color)
            
            // Message
            Text(message)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.TextColors.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                        .stroke(type.color.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(
            color: type.color.opacity(0.3),
            radius: 12,
            x: 0,
            y: 4
        )
        .padding(.horizontal, AppTheme.Spacing.m)
        .offset(y: offset + dragOffset)
        .opacity(opacity)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    // Only allow upward swipe
                    if gesture.translation.height < 0 {
                        dragOffset = gesture.translation.height
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.height < -50 {
                        // Dismiss if swiped up enough
                        dismiss()
                    } else {
                        // Return to position
                        withAnimation(AppTheme.AnimationCurves.spring) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            // Slide in animation with fade
            withAnimation(AppTheme.AnimationCurves.spring) {
                offset = 60
                opacity = 1
            }
            
            // Auto-dismiss after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                dismiss()
            }
        }
    }
    
    // MARK: - Methods
    
    private func dismiss() {
        withAnimation(AppTheme.AnimationCurves.spring) {
            offset = -100
            opacity = 0
        }
        
        // Call onDismiss callback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

// MARK: - Toast Manager

class ToastManager: ObservableObject {
    @Published var toast: ToastData?
    
    struct ToastData: Identifiable {
        let id = UUID()
        let message: String
        let type: ToastNotification.NotificationType
        let duration: Double
    }
    
    func show(message: String, type: ToastNotification.NotificationType, duration: Double = 3.0) {
        toast = ToastData(message: message, type: type, duration: duration)
    }
    
    func dismiss() {
        toast = nil
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let toast = toastManager.toast {
                VStack {
                    ToastNotification(
                        message: toast.message,
                        type: toast.type,
                        duration: toast.duration,
                        onDismiss: {
                            toastManager.dismiss()
                        }
                    )
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
    }
}

extension View {
    func toast(manager: ToastManager) -> some View {
        self.modifier(ToastModifier(toastManager: manager))
    }
}

// MARK: - Preview

struct ToastNotification_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.primaryGradient
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.xxl) {
                Spacer()
                
                // Success toast
                ToastNotification(
                    message: "Successfully saved!",
                    type: .success,
                    duration: 5.0
                )
                
                // Error toast
                ToastNotification(
                    message: "Failed to connect to server",
                    type: .error,
                    duration: 5.0
                )
                
                // Info toast
                ToastNotification(
                    message: "New message received",
                    type: .info,
                    duration: 5.0
                )
                
                // Warning toast
                ToastNotification(
                    message: "Your session will expire soon",
                    type: .warning,
                    duration: 5.0
                )
                
                Spacer()
            }
        }
    }
}
