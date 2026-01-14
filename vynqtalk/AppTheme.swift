//
//  AppTheme.swift
//  vynqtalk
//
//  Design System Foundation
//  Provides centralized theming for colors, typography, spacing, and animations
//

import SwiftUI

struct AppTheme {
    
    // MARK: - Color Palette
    
    /// Primary gradient colors for backgrounds
    struct GradientColors {
        static let deepNavyBlack = Color(red: 0.05, green: 0.05, blue: 0.1)
        static let midnightBlue = Color(red: 0.1, green: 0.15, blue: 0.3).opacity(0.8)
        static let softBlue = Color(red: 0.2, green: 0.3, blue: 0.5).opacity(0.6)
    }
    
    /// Primary gradient configuration
    static let primaryGradient = LinearGradient(
        colors: [
            GradientColors.deepNavyBlack,
            GradientColors.midnightBlue,
            GradientColors.softBlue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Accent colors for interactive elements and states
    struct AccentColors {
        static let primary = Color(red: 0.3, green: 0.5, blue: 1.0)
        static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.2)
        static let error = Color(red: 1.0, green: 0.3, blue: 0.3)
    }
    
    /// Text color hierarchy
    struct TextColors {
        static let primary = Color.white
        static let secondary = Color.white.opacity(0.8)
        static let tertiary = Color.white.opacity(0.6)
        static let disabled = Color.white.opacity(0.4)
    }
    
    /// Surface and background colors
    struct SurfaceColors {
        static let surface = Color.white.opacity(0.1)
        static let surfaceLight = Color.white.opacity(0.06)
        static let surfaceMedium = Color.white.opacity(0.12)
    }
    
    // MARK: - Typography
    
    /// Font sizes following iOS design guidelines
    struct FontSizes {
        static let largeTitle: CGFloat = 34
        static let title: CGFloat = 28
        static let title2: CGFloat = 22
        static let title3: CGFloat = 20
        static let headline: CGFloat = 17
        static let body: CGFloat = 17
        static let callout: CGFloat = 16
        static let subheadline: CGFloat = 15
        static let footnote: CGFloat = 13
        static let caption: CGFloat = 12
        static let caption2: CGFloat = 11
    }
    
    /// Font weights
    struct FontWeights {
        static let ultraLight = Font.Weight.ultraLight
        static let thin = Font.Weight.thin
        static let light = Font.Weight.light
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
        static let heavy = Font.Weight.heavy
        static let black = Font.Weight.black
    }
    
    /// Typography scale with predefined font styles
    struct Typography {
        static let largeTitle = Font.system(size: FontSizes.largeTitle, weight: FontWeights.bold)
        static let title = Font.system(size: FontSizes.title, weight: FontWeights.bold)
        static let title2 = Font.system(size: FontSizes.title2, weight: FontWeights.semibold)
        static let title3 = Font.system(size: FontSizes.title3, weight: FontWeights.semibold)
        static let headline = Font.system(size: FontSizes.headline, weight: FontWeights.semibold)
        static let body = Font.system(size: FontSizes.body, weight: FontWeights.regular)
        static let bodyMedium = Font.system(size: FontSizes.body, weight: FontWeights.medium)
        static let callout = Font.system(size: FontSizes.callout, weight: FontWeights.regular)
        static let subheadline = Font.system(size: FontSizes.subheadline, weight: FontWeights.regular)
        static let footnote = Font.system(size: FontSizes.footnote, weight: FontWeights.regular)
        static let caption = Font.system(size: FontSizes.caption, weight: FontWeights.regular)
        static let caption2 = Font.system(size: FontSizes.caption2, weight: FontWeights.regular)
    }
    
    // MARK: - Spacing
    
    /// Spacing scale for consistent padding and margins
    struct Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    /// Corner radius values for rounded elements
    struct CornerRadius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
    }
    
    // MARK: - Animations
    
    /// Animation duration constants
    struct AnimationDuration {
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.5
    }
    
    /// Predefined animation curves
    struct AnimationCurves {
        static let spring = Animation.spring(response: 0.3, dampingFraction: 0.6)
        static let easeInOut = Animation.easeInOut(duration: AnimationDuration.normal)
        static let easeIn = Animation.easeIn(duration: AnimationDuration.normal)
        static let easeOut = Animation.easeOut(duration: AnimationDuration.normal)
        static let linear = Animation.linear(duration: AnimationDuration.normal)
        
        // Specific animation curves for common interactions
        static let buttonPress = Animation.spring(response: 0.15, dampingFraction: 0.6)
        static let screenTransition = Animation.easeInOut(duration: AnimationDuration.slow)
        static let componentAppearance = Animation.easeOut(duration: AnimationDuration.normal)
    }
    
    // MARK: - Shadows
    
    /// Shadow configurations for depth
    struct Shadows {
        static let small = (color: Color.black.opacity(0.1), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Color.black.opacity(0.2), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
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
            AppTheme.GradientColors.deepNavyBlack,
            AppTheme.GradientColors.midnightBlue,
            AppTheme.GradientColors.softBlue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
        animates: true
    )
}
