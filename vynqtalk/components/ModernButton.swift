//
//  ModernButton.swift
//  vynqtalk
//
//  Modern button component matching onboarding design
//

import SwiftUI

struct ModernButton: View {
    let title: String
    let style: ButtonStyle
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var appeared = false
    
    enum ButtonStyle {
        case primary    // White background like onboarding
        case secondary  // Outlined style
        case accent     // Gradient accent
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundView)
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                y: shadowY
            )
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .disabled(isDisabled || isLoading)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && !isDisabled && !isLoading {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = false
                    }
                }
        )
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            Color.white
        case .secondary:
            Color.clear
        case .accent:
            LinearGradient(
                colors: [
                    AppTheme.AccentColors.primary,
                    AppTheme.AccentColors.secondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var textColor: Color {
        if isDisabled {
            return .white.opacity(0.4)
        }
        
        switch style {
        case .primary:
            return AppTheme.GradientColors.deepBlack
        case .secondary, .accent:
            return .white
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .secondary:
            return .white.opacity(0.3)
        default:
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .secondary:
            return 2
        default:
            return 0
        }
    }
    
    private var shadowColor: Color {
        if isDisabled { return .clear }
        
        switch style {
        case .primary:
            return .white.opacity(0.3)
        case .accent:
            return AppTheme.AccentColors.primary.opacity(0.4)
        default:
            return .clear
        }
    }
    
    private var shadowRadius: CGFloat {
        if isDisabled { return 0 }
        
        switch style {
        case .primary:
            return 15
        case .accent:
            return 20
        default:
            return 0
        }
    }
    
    private var shadowY: CGFloat {
        if isDisabled { return 0 }
        return isPressed ? 2 : 8
    }
    
    private var scale: CGFloat {
        if isDisabled {
            return 1.0
        }
        return isPressed ? 0.96 : 1.0
    }
    
    private var opacity: Double {
        return isDisabled ? 0.6 : 1.0
    }
}