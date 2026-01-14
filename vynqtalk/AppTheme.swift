//
//  AppTheme.swift
//  vynqtalk
//
//  Design System Foundation
//  Provides centralized theming for colors, typography, spacing, and animations
//

import SwiftUI

struct AppTheme {
    
    // MARK: - Color Palette (Tech Professional Theme)
    
    /// Primary gradient colors for backgrounds
    struct GradientColors {
        static let deepBlack = Color(red: 0.03, green: 0.04, blue: 0.08)      // #080A14
        static let richBlack = Color(red: 0.06, green: 0.08, blue: 0.12)      // #0F141F
        static let darkGray = Color(red: 0.10, green: 0.12, blue: 0.16)       // #1A1F29
        
        // Legacy names for compatibility
        static let deepPurple = deepBlack
        static let richPurple = richBlack
        static let deepBlue = darkGray
        static let deepNavyBlack = deepBlack
        static let midnightBlue = richBlack
        static let softBlue = darkGray
    }
    
    /// Primary gradient configuration
    static let primaryGradient = LinearGradient(
        colors: [
            GradientColors.deepBlack,
            GradientColors.richBlack,
            GradientColors.darkGray
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Accent colors for interactive elements and states
    struct AccentColors {
        static let primary = Color(red: 0.20, green: 0.60, blue: 1.0)          // #3399FF (Electric Blue)
        static let secondary = Color(red: 0.25, green: 0.70, blue: 1.0)        // #40B3FF (Bright Blue)
        static let success = Color(red: 0.25, green: 0.85, blue: 0.65)         // #40D9A6 (Mint Green)
        static let online = Color(red: 0.30, green: 0.90, blue: 0.70)          // #4DE6B3 (Bright Green)
        static let warning = Color(red: 1.0, green: 0.70, blue: 0.30)          // #FFB34D (Warm Orange)
        static let error = Color(red: 1.0, green: 0.40, blue: 0.50)            // #FF6680 (Coral Red)
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
        static let surface = Color.white.opacity(0.08)                          // Subtle glass
        static let surfaceLight = Color.white.opacity(0.05)                     // Very subtle
        static let surfaceMedium = Color.white.opacity(0.12)                    // More visible
        static let surfaceElevated = Color.white.opacity(0.15)                  // Elevated cards
    }
    
    /// Message bubble colors
    struct MessageColors {
        // Sent messages - Electric Blue gradient
        static let sentStart = Color(red: 0.20, green: 0.60, blue: 1.0)        // #3399FF
        static let sentEnd = Color(red: 0.15, green: 0.50, blue: 0.90)         // #2680E6
        
        // Received messages - Dark elevated surface
        static let received = Color(red: 0.10, green: 0.12, blue: 0.16)        // #1A1F29
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

// MARK: - Accessibility

/// Accessibility utilities for WCAG compliance
extension AppTheme {
    
    /// WCAG AA contrast ratio standards
    struct ContrastStandards {
        /// Minimum contrast ratio for normal text (4.5:1)
        static let normalText: Double = 4.5
        
        /// Minimum contrast ratio for large text (3:1)
        /// Large text is defined as 18pt+ regular or 14pt+ bold
        static let largeText: Double = 3.0
        
        /// Enhanced contrast ratio for AAA compliance (7:1)
        static let enhancedNormalText: Double = 7.0
        
        /// Enhanced contrast ratio for large text AAA compliance (4.5:1)
        static let enhancedLargeText: Double = 4.5
    }
    
    /// Calculate the contrast ratio between two colors
    /// - Parameters:
    ///   - foreground: The foreground color (typically text)
    ///   - background: The background color
    /// - Returns: The contrast ratio as a Double (1.0 to 21.0)
    static func contrastRatio(foreground: Color, background: Color) -> Double {
        let foregroundLuminance = relativeLuminance(of: foreground)
        let backgroundLuminance = relativeLuminance(of: background)
        
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Check if a color combination meets WCAG AA standards
    /// - Parameters:
    ///   - foreground: The foreground color (typically text)
    ///   - background: The background color
    ///   - isLargeText: Whether the text is considered large (18pt+ regular or 14pt+ bold)
    /// - Returns: True if the contrast ratio meets WCAG AA standards
    static func meetsWCAGAA(foreground: Color, background: Color, isLargeText: Bool = false) -> Bool {
        let ratio = contrastRatio(foreground: foreground, background: background)
        let requiredRatio = isLargeText ? ContrastStandards.largeText : ContrastStandards.normalText
        return ratio >= requiredRatio
    }
    
    /// Check if a color combination meets WCAG AAA standards
    /// - Parameters:
    ///   - foreground: The foreground color (typically text)
    ///   - background: The background color
    ///   - isLargeText: Whether the text is considered large (18pt+ regular or 14pt+ bold)
    /// - Returns: True if the contrast ratio meets WCAG AAA standards
    static func meetsWCAGAAA(foreground: Color, background: Color, isLargeText: Bool = false) -> Bool {
        let ratio = contrastRatio(foreground: foreground, background: background)
        let requiredRatio = isLargeText ? ContrastStandards.enhancedLargeText : ContrastStandards.enhancedNormalText
        return ratio >= requiredRatio
    }
    
    /// Calculate the relative luminance of a color
    /// - Parameter color: The color to calculate luminance for
    /// - Returns: The relative luminance value (0.0 to 1.0)
    private static func relativeLuminance(of color: Color) -> Double {
        // Convert SwiftUI Color to UIColor to extract RGB components
        let uiColor = UIColor(color)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Apply gamma correction
        let r = gammaCorrect(red)
        let g = gammaCorrect(green)
        let b = gammaCorrect(blue)
        
        // Calculate relative luminance using the formula:
        // L = 0.2126 * R + 0.7152 * G + 0.0722 * B
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    /// Apply gamma correction to a color component
    /// - Parameter component: The color component value (0.0 to 1.0)
    /// - Returns: The gamma-corrected value
    private static func gammaCorrect(_ component: CGFloat) -> Double {
        let value = Double(component)
        if value <= 0.03928 {
            return value / 12.92
        } else {
            return pow((value + 0.055) / 1.055, 2.4)
        }
    }
    
    /// Validate all theme color combinations for WCAG AA compliance
    /// - Returns: Array of validation results with color pairs and their contrast ratios
    static func validateThemeContrast() -> [ContrastValidationResult] {
        var results: [ContrastValidationResult] = []
        
        // Validate text colors against gradient backgrounds
        let backgroundColors = [
            ("Deep Navy Black", GradientColors.deepNavyBlack),
            ("Midnight Blue", GradientColors.midnightBlue),
            ("Soft Blue", GradientColors.softBlue)
        ]
        
        let textColors = [
            ("Primary Text", TextColors.primary, false),
            ("Secondary Text", TextColors.secondary, false),
            ("Tertiary Text", TextColors.tertiary, false),
            ("Disabled Text", TextColors.disabled, false)
        ]
        
        for (bgName, bgColor) in backgroundColors {
            for (textName, textColor, isLarge) in textColors {
                let ratio = contrastRatio(foreground: textColor, background: bgColor)
                let meetsAA = meetsWCAGAA(foreground: textColor, background: bgColor, isLargeText: isLarge)
                
                results.append(ContrastValidationResult(
                    foregroundName: textName,
                    backgroundName: bgName,
                    contrastRatio: ratio,
                    meetsWCAGAA: meetsAA,
                    isLargeText: isLarge
                ))
            }
        }
        
        // Validate accent colors against dark backgrounds
        let accentColors = [
            ("Primary Accent", AccentColors.primary),
            ("Success", AccentColors.success),
            ("Warning", AccentColors.warning),
            ("Error", AccentColors.error)
        ]
        
        for (bgName, bgColor) in backgroundColors {
            for (accentName, accentColor) in accentColors {
                let ratio = contrastRatio(foreground: accentColor, background: bgColor)
                let meetsAA = meetsWCAGAA(foreground: accentColor, background: bgColor, isLargeText: false)
                
                results.append(ContrastValidationResult(
                    foregroundName: accentName,
                    backgroundName: bgName,
                    contrastRatio: ratio,
                    meetsWCAGAA: meetsAA,
                    isLargeText: false
                ))
            }
        }
        
        return results
    }
    
    // MARK: - Touch Target Sizes
    
    /// Minimum touch target size for iOS (44x44 points)
    struct TouchTargetSize {
        /// Minimum width for touch targets (44 points)
        static let minimumWidth: CGFloat = 44
        
        /// Minimum height for touch targets (44 points)
        static let minimumHeight: CGFloat = 44
        
        /// Recommended comfortable touch target size (48 points)
        static let comfortable: CGFloat = 48
        
        /// Large touch target for primary actions (56 points)
        static let large: CGFloat = 56
    }
    
    /// Check if a size meets minimum touch target requirements
    /// - Parameters:
    ///   - width: The width of the touch target
    ///   - height: The height of the touch target
    /// - Returns: True if the size meets iOS minimum requirements (44x44)
    static func meetsTouchTargetSize(width: CGFloat, height: CGFloat) -> Bool {
        return width >= TouchTargetSize.minimumWidth && height >= TouchTargetSize.minimumHeight
    }
    
    /// Check if a size meets minimum touch target requirements
    /// - Parameter size: The size of the touch target
    /// - Returns: True if the size meets iOS minimum requirements (44x44)
    static func meetsTouchTargetSize(_ size: CGSize) -> Bool {
        return meetsTouchTargetSize(width: size.width, height: size.height)
    }
    
    /// Get the minimum frame size for a touch target
    /// - Returns: CGSize with minimum dimensions (44x44)
    static func minimumTouchTargetFrame() -> CGSize {
        return CGSize(width: TouchTargetSize.minimumWidth, height: TouchTargetSize.minimumHeight)
    }
}

/// Result of a contrast validation check
struct ContrastValidationResult {
    let foregroundName: String
    let backgroundName: String
    let contrastRatio: Double
    let meetsWCAGAA: Bool
    let isLargeText: Bool
    
    var description: String {
        let status = meetsWCAGAA ? "✓ PASS" : "✗ FAIL"
        let standard = isLargeText ? "3:1" : "4.5:1"
        return "\(status) \(foregroundName) on \(backgroundName): \(String(format: "%.2f", contrastRatio)):1 (Required: \(standard))"
    }
}

// MARK: - Accessibility View Modifiers

extension View {
    /// Ensures a view meets minimum touch target size requirements
    /// - Parameters:
    ///   - minWidth: Minimum width (default: 44 points)
    ///   - minHeight: Minimum height (default: 44 points)
    /// - Returns: Modified view with minimum frame size
    func accessibleTouchTarget(minWidth: CGFloat = 44, minHeight: CGFloat = 44) -> some View {
        self.frame(minWidth: minWidth, minHeight: minHeight)
    }
    
    /// Applies standard accessibility touch target size (44x44)
    /// - Returns: Modified view with minimum touch target frame
    func minimumTouchTarget() -> some View {
        self.frame(
            minWidth: AppTheme.TouchTargetSize.minimumWidth,
            minHeight: AppTheme.TouchTargetSize.minimumHeight
        )
    }
    
    /// Applies comfortable touch target size (48x48)
    /// - Returns: Modified view with comfortable touch target frame
    func comfortableTouchTarget() -> some View {
        self.frame(
            minWidth: AppTheme.TouchTargetSize.comfortable,
            minHeight: AppTheme.TouchTargetSize.comfortable
        )
    }
}
