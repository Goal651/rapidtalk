//
//  PremiumButton.swift
//  vynqtalk
//
//  Premium Button Component - Apple Quality Design
//  Glass effects with sophisticated animations
//

import SwiftUI

struct PremiumButton: View {
    let title: String
    let style: ButtonStyle
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var icon: String? = nil
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary        // Blue gradient with glass
        case secondary      // Glass with border
        case tertiary       // Subtle glass
        case destructive    // Red gradient
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: AppTheme.Layout.spacing12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(title)
                        .font(AppTheme.Typography.buttonLarge)
                }
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Layout.buttonHeight)
            .background(backgroundView)
            .overlay(overlayView)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusButton))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                y: shadowY
            )
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .disabled(isDisabled || isLoading)
        .animation(AppTheme.Animations.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && !isDisabled && !isLoading {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            AppTheme.AccentColors.primaryGradient
        case .secondary:
            AppTheme.GlassMaterials.thick
        case .tertiary:
            AppTheme.GlassMaterials.thin
        case .destructive:
            LinearGradient(
                colors: [
                    AppTheme.AccentColors.error,
                    AppTheme.AccentColors.error.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusButton)
            .stroke(borderGradient, lineWidth: borderWidth)
    }
    
    private var borderGradient: LinearGradient {
        switch style {
        case .primary, .destructive:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.white.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return LinearGradient(
                colors: [
                    AppTheme.AccentColors.primary.opacity(0.6),
                    AppTheme.AccentColors.primary.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .tertiary:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var textColor: Color {
        if isDisabled {
            return AppTheme.TextColors.disabled
        }
        
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return AppTheme.AccentColors.primary
        case .tertiary:
            return AppTheme.TextColors.primary
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .secondary:
            return 1.5
        default:
            return 0.5
        }
    }
    
    private var shadowColor: Color {
        if isDisabled { return .clear }
        
        switch style {
        case .primary:
            return AppTheme.AccentColors.primary.opacity(0.4)
        case .destructive:
            return AppTheme.AccentColors.error.opacity(0.4)
        default:
            return Color.black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        if isDisabled { return 0 }
        
        switch style {
        case .primary, .destructive:
            return isPressed ? 8 : 16
        default:
            return isPressed ? 4 : 8
        }
    }
    
    private var shadowY: CGFloat {
        if isDisabled { return 0 }
        return isPressed ? 2 : 6
    }
    
    private var scale: CGFloat {
        if isDisabled {
            return 1.0
        }
        return isPressed ? 0.97 : 1.0
    }
    
    private var opacity: Double {
        return isDisabled ? 0.5 : 1.0
    }
}

// MARK: - Premium Icon Button

struct PremiumIconButton: View {
    let icon: String
    let style: IconButtonStyle
    var size: IconButtonSize = .medium
    let action: () -> Void
    
    @State private var isPressed = false
    
    enum IconButtonStyle {
        case primary
        case secondary
        case tertiary
    }
    
    enum IconButtonSize {
        case small
        case medium
        case large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 18
            case .large: return 22
            }
        }
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: size.dimension, height: size.dimension)
                .background(backgroundView)
                .overlay(overlayView)
                .clipShape(Circle())
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius,
                    y: shadowY
                )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(AppTheme.Animations.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            AppTheme.AccentColors.primaryGradient
        case .secondary:
            AppTheme.GlassMaterials.thick
        case .tertiary:
            AppTheme.GlassMaterials.thin
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        Circle()
            .stroke(borderGradient, lineWidth: 0.5)
    }
    
    private var borderGradient: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.white.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary, .tertiary:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var iconColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .tertiary:
            return AppTheme.TextColors.primary
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return AppTheme.AccentColors.primary.opacity(0.3)
        default:
            return Color.black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary:
            return isPressed ? 6 : 12
        default:
            return isPressed ? 3 : 6
        }
    }
    
    private var shadowY: CGFloat {
        return isPressed ? 2 : 4
    }
}

// MARK: - Premium Floating Action Button

struct PremiumFloatingActionButton: View {
    let icon: String
    var size: FloatingButtonSize = .standard
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var appeared = false
    
    enum FloatingButtonSize {
        case compact
        case standard
        case large
        
        var dimension: CGFloat {
            switch self {
            case .compact: return 48
            case .standard: return 56
            case .large: return 64
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .compact: return 20
            case .standard: return 24
            case .large: return 28
            }
        }
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size.dimension, height: size.dimension)
                .background(
                    Circle()
                        .fill(AppTheme.AccentColors.primaryGradient)
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .scaleEffect(isPressed ? 0.95 : (appeared ? 1.0 : 0.8))
        .opacity(appeared ? 1 : 0)
        .shadow(
            color: AppTheme.AccentColors.primary.opacity(0.4),
            radius: isPressed ? 12 : 20,
            y: isPressed ? 4 : 8
        )
        .animation(AppTheme.Animations.buttonPress, value: isPressed)
        .animation(AppTheme.Animations.springBouncy, value: appeared)
        .onAppear {
            withAnimation(AppTheme.Animations.springBouncy.delay(0.3)) {
                appeared = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}