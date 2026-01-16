//
//  ModernButton.swift
//  vynqtalk
//
//  Premium button component with simplified animations
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
    
    enum ButtonStyle {
        case primary    // Blue background
        case secondary  // Outlined style
        case tertiary   // Subtle background
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Layout.buttonHeight)
            .background(backgroundView)
            .cornerRadius(AppTheme.Layout.cornerRadiusButton)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusButton)
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
        .animation(AppTheme.AnimationCurves.buttonPress, value: isPressed)
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
            AppTheme.AccentColors.primary
        case .secondary:
            Color.clear
        case .tertiary:
            AppTheme.SurfaceColors.base
        }
    }
    
    private var textColor: Color {
        if isDisabled {
            return AppTheme.TextColors.disabled
        }
        
        switch style {
        case .primary:
            return .white
        case .secondary:
            return AppTheme.AccentColors.primary
        case .tertiary:
            return .white
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .secondary:
            return AppTheme.AccentColors.primary.opacity(0.5)
        default:
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .secondary:
            return 1.5
        default:
            return 0
        }
    }
    
    private var shadowColor: Color {
        if isDisabled { return .clear }
        
        switch style {
        case .primary:
            return AppTheme.AccentColors.primary.opacity(0.3)
        default:
            return .clear
        }
    }
    
    private var shadowRadius: CGFloat {
        if isDisabled { return 0 }
        
        switch style {
        case .primary:
            return isPressed ? 8 : 12
        default:
            return 0
        }
    }
    
    private var shadowY: CGFloat {
        if isDisabled { return 0 }
        return isPressed ? 2 : 4
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