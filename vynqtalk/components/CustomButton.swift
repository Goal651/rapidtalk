//
//  CustomButton.swift
//  vynqtalk
//
//  Reusable button component with multiple styles and animations
//

import SwiftUI

struct CustomButton: View {
    
    // MARK: - Button Style
    
    enum Style {
        case primary    // Solid white background
        case secondary  // Glass effect with border
        case accent     // Gradient accent color
        case text       // Text only, no background
    }
    
    // MARK: - Properties
    
    let title: String
    let style: Style
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var accessibilityLabel: String? = nil
    var accessibilityHint: String? = nil
    
    // MARK: - State
    
    @State private var isPressed: Bool = false
    @State private var isHovered: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                action()
            }
        }) {
            HStack(spacing: AppTheme.Spacing.s) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundView)
            .cornerRadius(AppTheme.CornerRadius.m)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: 2
            )
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .animation(AppTheme.AnimationCurves.buttonPress, value: isPressed)
        .animation(AppTheme.AnimationCurves.buttonPress, value: isHovered)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(accessibilityLabel ?? title)
        .accessibilityHint(accessibilityHint ?? "")
        .accessibilityAddTraits(isDisabled ? .isButton : [.isButton])
        .accessibilityRemoveTraits(isDisabled ? [] : [])
    }
    
    // MARK: - Computed Properties
    
    private var backgroundView: some View {
        Group {
            switch style {
            case .primary:
                Color.white
            case .secondary:
                Color.white.opacity(0.08)
                    .background(.ultraThinMaterial)
            case .accent:
                LinearGradient(
                    colors: [
                        AppTheme.AccentColors.primary,
                        Color(red: 0.45, green: 0.35, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .text:
                Color.clear
            }
        }
    }
    
    private var textColor: Color {
        if isDisabled {
            return AppTheme.TextColors.disabled
        }
        
        switch style {
        case .primary:
            return Color(red: 0.05, green: 0.05, blue: 0.1)
        case .secondary, .accent, .text:
            return AppTheme.TextColors.primary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .secondary:
            return Color.white.opacity(0.25)
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .secondary:
            return 1
        default:
            return 0
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary:
            return Color.white.opacity(0.2)
        case .accent:
            return AppTheme.AccentColors.primary.opacity(0.4)
        default:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary:
            return 8
        case .accent:
            return 15
        default:
            return 0
        }
    }
    
    private var scale: CGFloat {
        if isDisabled {
            return 1.0
        }
        if isPressed {
            return 0.95
        }
        if isHovered {
            return 1.05
        }
        return 1.0
    }
    
    private var opacity: Double {
        if isDisabled {
            return 0.5
        }
        return 1.0
    }
}

// MARK: - Preview

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.primaryGradient
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.l) {
                CustomButton(
                    title: "Primary Button",
                    style: .primary,
                    action: { print("Primary tapped") }
                )
                
                CustomButton(
                    title: "Secondary Button",
                    style: .secondary,
                    action: { print("Secondary tapped") }
                )
                
                CustomButton(
                    title: "Accent Button",
                    style: .accent,
                    action: { print("Accent tapped") }
                )
                
                CustomButton(
                    title: "Text Button",
                    style: .text,
                    action: { print("Text tapped") }
                )
                
                CustomButton(
                    title: "Loading",
                    style: .primary,
                    action: {},
                    isLoading: true
                )
                
                CustomButton(
                    title: "Disabled",
                    style: .primary,
                    action: {},
                    isDisabled: true
                )
            }
            .padding(AppTheme.Spacing.l)
        }
    }
}
