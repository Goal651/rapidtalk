//
//  AppTheme.swift
//  vynqtalk
//
//  Refined Premium Design System - Calmer & More Premium
//  Reduced visual noise by 20% for better focus
//

import SwiftUI

struct AppTheme {
    
    // MARK: - Calmer Color Palette (Reduced Noise)
    
    /// Background colors - Simplified, calmer
    struct BackgroundColors {
        static let primary = Color(red: 0.04, green: 0.04, blue: 0.06)        // Deep calm navy
        static let secondary = Color(red: 0.06, green: 0.06, blue: 0.08)      // Slightly elevated
        static let tertiary = Color(red: 0.08, green: 0.08, blue: 0.10)       // Cards and panels
        
        // Simplified gradient (less complex)
        static let primaryGradient = LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.04, blue: 0.06),
                Color(red: 0.06, green: 0.06, blue: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let chatGradient = LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.04, blue: 0.06),
                Color(red: 0.05, green: 0.05, blue: 0.07)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Simplified Glass Materials (Less Noise)
    struct GlassMaterials {
        // Reduced opacity for calmer effect
        static let ultraThin = Color.white.opacity(0.03)
        static let ultraThinBorder = Color.white.opacity(0.06)
        
        static let thin = Color.white.opacity(0.06)
        static let thinBorder = Color.white.opacity(0.10)
        
        static let thick = Color.white.opacity(0.10)
        static let thickBorder = Color.white.opacity(0.15)
        
        // Simplified premium glass (less complex gradient)
        static let premium = LinearGradient(
            colors: [
                Color.white.opacity(0.12),
                Color.white.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Calmer accent colors (Less saturated)
    struct AccentColors {
        static let primary = Color(red: 0.25, green: 0.65, blue: 1.0)         // Softer blue
        static let primarySoft = Color(red: 0.45, green: 0.75, blue: 1.0)     // Even softer
        static let secondary = Color(red: 0.65, green: 0.45, blue: 1.0)       // Muted purple-blue
        
        // Status colors (slightly muted)
        static let success = Color(red: 0.25, green: 0.75, blue: 0.40)        // Calmer green
        static let warning = Color(red: 1.0, green: 0.65, blue: 0.10)         // Softer orange
        static let error = Color(red: 1.0, green: 0.35, blue: 0.30)           // Softer red
        static let online = Color(red: 0.25, green: 0.75, blue: 0.40)
        
        // Simplified gradients
        static let primaryGradient = LinearGradient(
            colors: [primary, primarySoft],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let messageGradient = LinearGradient(
            colors: [
                Color(red: 0.20, green: 0.60, blue: 0.95),
                Color(red: 0.30, green: 0.70, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Text colors (Improved contrast for calmness)
    struct TextColors {
        static let primary = Color.white
        static let secondary = Color.white.opacity(0.80)
        static let tertiary = Color.white.opacity(0.60)
        static let quaternary = Color.white.opacity(0.40)
        static let disabled = Color.white.opacity(0.25)
        
        // Special text colors (muted)
        static let accent = Color(red: 0.25, green: 0.65, blue: 1.0)
        static let success = Color(red: 0.25, green: 0.75, blue: 0.40)
        static let warning = Color(red: 1.0, green: 0.65, blue: 0.10)
        static let error = Color(red: 1.0, green: 0.35, blue: 0.30)
    }
    
    /// Gradient colors for legacy compatibility
    struct GradientColors {
        static let deepBlack = Color(red: 0.02, green: 0.02, blue: 0.04)
        static let deepNavyBlack = Color(red: 0.03, green: 0.03, blue: 0.05)
        static let midnightBlue = Color(red: 0.05, green: 0.05, blue: 0.08)
        static let softBlue = Color(red: 0.15, green: 0.25, blue: 0.45)
    }
    
    /// Simplified surface colors
    struct SurfaceColors {
        static let base = Color.white.opacity(0.06)
        static let elevated = Color.white.opacity(0.10)
        static let overlay = Color.white.opacity(0.15)
        
        // Message bubbles (simplified)
        static let messageSent = AccentColors.primary
        static let messageReceived = Color.white.opacity(0.08)
        
        // Cards and panels (less complex)
        static let card = Color.white.opacity(0.08)
        static let panel = Color.white.opacity(0.10)
    }
    
    // MARK: - Simplified Layout Constants
    
    struct Layout {
        // Spacing (consistent 8pt grid)
        static let spacing4: CGFloat = 4
        static let spacing8: CGFloat = 8
        static let spacing12: CGFloat = 12
        static let spacing16: CGFloat = 16
        static let spacing20: CGFloat = 20
        static let spacing24: CGFloat = 24
        static let spacing32: CGFloat = 32
        static let spacing48: CGFloat = 48
        
        // Screen padding (simplified)
        static let screenPadding: CGFloat = 20
        static let screenPaddingIPad: CGFloat = 32
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 32
        
        // Component sizes (Apple standard)
        static let buttonHeight: CGFloat = 50
        static let buttonHeightSmall: CGFloat = 44
        static let iconButton: CGFloat = 44
        static let textFieldHeight: CGFloat = 50
        
        // Avatars (simplified sizes)
        static let avatarSmall: CGFloat = 32
        static let avatarMedium: CGFloat = 50
        static let avatarLarge: CGFloat = 70
        static let avatarXLarge: CGFloat = 100
        
        // Corner radius (consistent)
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        static let cornerRadiusXLarge: CGFloat = 20
        static let cornerRadiusButton: CGFloat = 25
        
        // Message bubbles (simplified)
        static let messageBubbleMaxWidth: CGFloat = 280
        static let messageBubbleRadius: CGFloat = 18
        
        // Glass effects (reduced)
        static let glassBlurRadius: CGFloat = 15
        static let glassBorderWidth: CGFloat = 0.5
        
        // iPad specific
        static let sidebarWidth: CGFloat = 340
        static let maxContentWidth: CGFloat = 680
    }
    
    // MARK: - Calmer Typography (SF Pro)
    
    struct Typography {
        // Large titles (simplified weights)
        static let largeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title = Font.system(size: 26, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 18, weight: .medium, design: .rounded)
        
        // Body text (consistent)
        static let headline = Font.system(size: 16, weight: .medium, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let bodyMedium = Font.system(size: 16, weight: .medium, design: .rounded)
        static let callout = Font.system(size: 15, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 14, weight: .regular, design: .rounded)
        
        // Small text (simplified)
        static let footnote = Font.system(size: 12, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 11, weight: .regular, design: .rounded)
        static let caption2 = Font.system(size: 10, weight: .regular, design: .rounded)
        
        // Button text (consistent)
        static let buttonLarge = Font.system(size: 16, weight: .medium, design: .rounded)
        static let buttonMedium = Font.system(size: 15, weight: .medium, design: .rounded)
        static let buttonSmall = Font.system(size: 14, weight: .medium, design: .rounded)
    }
    
    // MARK: - Calmer Animations (Reduced Motion)
    
    struct Animations {
        // Durations (slightly slower for calmness)
        static let fast: Double = 0.25
        static let normal: Double = 0.4
        static let slow: Double = 0.6
        
        // Calmer spring curves
        static let spring = Animation.spring(response: 0.5, dampingFraction: 0.85)
        static let springBouncy = Animation.spring(response: 0.6, dampingFraction: 0.75)
        static let springSnappy = Animation.spring(response: 0.4, dampingFraction: 0.9)
        
        // Easing curves (smoother)
        static let easeOut = Animation.easeOut(duration: normal)
        static let easeInOut = Animation.easeInOut(duration: normal)
        
        // Interaction animations (gentler)
        static let buttonPress = Animation.easeInOut(duration: 0.15)
        static let cardAppear = Animation.easeOut(duration: 0.5)
        static let slideTransition = Animation.easeInOut(duration: 0.4)
        
        // Glass material animations (subtle)
        static let glassAppear = Animation.easeOut(duration: 0.5)
        static let glassHover = Animation.easeInOut(duration: 0.3)
    }
    
    // MARK: - Subtle Shadows (Reduced Noise)
    
    struct Shadows {
        // Gentler shadows
        static let glass = (
            color: Color.black.opacity(0.10),
            radius: CGFloat(15),
            x: CGFloat(0),
            y: CGFloat(6)
        )
        
        static let card = (
            color: Color.black.opacity(0.15),
            radius: CGFloat(12),
            x: CGFloat(0),
            y: CGFloat(4)
        )
        
        static let button = (
            color: AccentColors.primary.opacity(0.25),
            radius: CGFloat(10),
            x: CGFloat(0),
            y: CGFloat(3)
        )
        
        static let floating = (
            color: Color.black.opacity(0.20),
            radius: CGFloat(18),
            x: CGFloat(0),
            y: CGFloat(8)
        )
    }
}

// MARK: - Simplified Glass Effect Modifiers

extension View {
    /// Ultra-thin glass (minimal)
    func ultraThinGlass(cornerRadius: CGFloat = AppTheme.Layout.cornerRadiusMedium) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    /// Thin glass (subtle)
    func thinGlass(cornerRadius: CGFloat = AppTheme.Layout.cornerRadiusMedium) -> some View {
        self
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    /// Thick glass (more prominent)
    func thickGlass(cornerRadius: CGFloat = AppTheme.Layout.cornerRadiusLarge) -> some View {
        self
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    /// Premium glass card (simplified)
    func premiumGlassCard(cornerRadius: CGFloat = AppTheme.Layout.cornerRadiusLarge) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.SurfaceColors.card)
            )
    }
    
    /// Gentle glass shadow
    func glassShadow() -> some View {
        self.shadow(
            color: AppTheme.Shadows.glass.color,
            radius: AppTheme.Shadows.glass.radius,
            x: AppTheme.Shadows.glass.x,
            y: AppTheme.Shadows.glass.y
        )
    }
    
    /// Card shadow (subtle)
    func cardShadow() -> some View {
        self.shadow(
            color: AppTheme.Shadows.card.color,
            radius: AppTheme.Shadows.card.radius,
            x: AppTheme.Shadows.card.x,
            y: AppTheme.Shadows.card.y
        )
    }
    
    /// Floating shadow (gentle)
    func floatingShadow() -> some View {
        self.shadow(
            color: AppTheme.Shadows.floating.color,
            radius: AppTheme.Shadows.floating.radius,
            x: AppTheme.Shadows.floating.x,
            y: AppTheme.Shadows.floating.y
        )
    }
}

// MARK: - Legacy Compatibility (Simplified)

extension AppTheme {
    // Legacy color mappings
    struct MessageColors {
        static let sent = AccentColors.primary
        static let received = SurfaceColors.messageReceived
        static let sentStart = AccentColors.primary
        static let sentEnd = AccentColors.primarySoft
    }
    
    // Legacy spacing
    struct Spacing {
        static let xs = Layout.spacing4
        static let s = Layout.spacing8
        static let m = Layout.spacing16
        static let l = Layout.spacing24
        static let xl = Layout.spacing32
        static let xxl = Layout.spacing48
    }
    
    // Legacy corner radius
    struct CornerRadius {
        static let s = Layout.cornerRadiusSmall
        static let m = Layout.cornerRadiusMedium
        static let l = Layout.cornerRadiusLarge
        static let xl = Layout.cornerRadiusXLarge
    }
    
    // Legacy animation curves
    struct AnimationCurves {
        static let spring = Animations.spring
        static let springBouncy = Animations.springBouncy
        static let easeInOut = Animations.easeInOut
        static let easeOut = Animations.easeOut
        static let buttonPress = Animations.buttonPress
        static let screenTransition = Animations.slideTransition
        static let componentAppearance = Animations.cardAppear
    }
    
    // Legacy animation duration
    struct AnimationDuration {
        static let fast = Animations.fast
        static let normal = Animations.normal
        static let slow = Animations.slow
    }
    
    // Legacy gradient
    static let primaryGradient = BackgroundColors.primaryGradient
}

// MARK: - Gradient Configuration Model

/// Configuration for animated gradients
struct GradientConfiguration {
    let colors: [Color]
    let startPoint: UnitPoint
    let endPoint: UnitPoint
    let animates: Bool
    
    init(
        colors: [Color],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing,
        animates: Bool = false
    ) {
        self.colors = colors
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.animates = animates
    }
    
    /// Default primary gradient configuration
    static let primary = GradientConfiguration(
        colors: [
            AppTheme.BackgroundColors.primary,
            AppTheme.BackgroundColors.secondary,
            AppTheme.BackgroundColors.tertiary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
        animates: true
    )
}