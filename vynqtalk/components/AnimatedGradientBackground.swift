//
//  AnimatedGradientBackground.swift
//  vynqtalk
//
//  Subtle animated gradient background with premium dark theme
//

import SwiftUI

struct AnimatedGradientBackground: View {
    
    // MARK: - Properties
    
    var colors: [Color]
    var animationDuration: Double = 8.0
    var startPoint: UnitPoint = .topLeading
    var endPoint: UnitPoint = .bottomTrailing
    var animates: Bool = false  // Disabled by default for cleaner look
    
    // MARK: - State
    
    @State private var animateGradient: Bool = false
    
    // MARK: - Initializer
    
    init(
        colors: [Color]? = nil,
        animationDuration: Double = 8.0,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing,
        animates: Bool = false
    ) {
        // Use provided colors or default to subtle dark gradient
        self.colors = colors ?? [
            AppTheme.BackgroundColors.primary,
            AppTheme.BackgroundColors.secondary,
            AppTheme.BackgroundColors.tertiary
        ]
        self.animationDuration = animationDuration
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.animates = animates
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: colors,
                startPoint: startPoint,
                endPoint: endPoint
            )
            .ignoresSafeArea()
            
            // Animated overlay gradient (if animation is enabled)
            if animates {
                LinearGradient(
                    colors: animateGradient ? colors.reversed() : colors,
                    startPoint: animateGradient ? endPoint : startPoint,
                    endPoint: animateGradient ? startPoint : endPoint
                )
                .opacity(0.3)
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(
                        .linear(duration: animationDuration)
                        .repeatForever(autoreverses: true)
                    ) {
                        animateGradient = true
                    }
                }
            }
        }
    }
}

// MARK: - Convenience Initializer with GradientConfiguration

extension AnimatedGradientBackground {
    init(configuration: GradientConfiguration) {
        self.init(
            colors: configuration.colors,
            startPoint: configuration.startPoint,
            endPoint: configuration.endPoint,
            animates: configuration.animates
        )
    }
}

// MARK: - Preview

struct AnimatedGradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            // Default animated gradient
            ZStack {
                AnimatedGradientBackground()
                
                Text("Default Animated Gradient")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.TextColors.primary)
            }
            .frame(height: 200)
            
            // Custom colors without animation
            ZStack {
                AnimatedGradientBackground(
                    colors: [
                        AppTheme.AccentColors.primary,
                        AppTheme.AccentColors.primary.opacity(0.6),
                        AppTheme.GradientColors.softBlue
                    ],
                    animates: false
                )
                
                Text("Custom Static Gradient")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.TextColors.primary)
            }
            .frame(height: 200)
            
            // Custom start/end points
            ZStack {
                AnimatedGradientBackground(
                    colors: [
                        AppTheme.AccentColors.success,
                        AppTheme.AccentColors.primary,
                        AppTheme.AccentColors.warning
                    ],
                    startPoint: .top,
                    endPoint: .bottom,
                    animates: true
                )
                
                Text("Vertical Animated Gradient")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.TextColors.primary)
            }
            .frame(height: 200)
            
            // Using GradientConfiguration
            ZStack {
                AnimatedGradientBackground(configuration: .primary)
                
                Text("Primary Configuration")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(AppTheme.TextColors.primary)
            }
            .frame(height: 200)
        }
    }
}
