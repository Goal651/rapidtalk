//
//  AppTheme.swift
//  vynqtalk
//
//  Design System Foundation
//  Premium polished theme with sophisticated colors and consistent spacing
//

import SwiftUI

struct AppTheme {
    
    // MARK: - Color Palette (Premium Theme)
    
    /// Background colors - True dark mode
    struct BackgroundColors {
        static let primary = Color(red: 0.07, green: 0.07, blue: 0.07)        // #121212 - Main background
        static let secondary = Color(red: 0.10, green: 0.10, blue: 0.10)      // #1A1A1A - Elevated surfaces
        static let tertiary = Color(red: 0.13, green: 0.13, blue: 0.13)       // #212121 - Cards/modals
    }
    
    /// Accent colors - Sophisticated blue palette
    struct AccentColors {
        static let primary = Color(red: 0.04, green: 0.52, blue: 1.0)         // #0A84FF - Apple blue
        static let primaryDark = Color(red: 0.03, green: 0.42, blue: 0.85)    // #0869D9 - Darker variant
        static let secondary = Color(red: 0.25, green: 0.70, blue: 1.0)       // #40B3FF - Lighter blue (legacy)
        static let success = Color(red: 0.20, green: 0.78, blue: 0.35)        // #34C759 - iOS green
        static let online = Color(red: 0.20, green: 0.78, blue: 0.35)         // #34C759 - Same as success
        static let warning = Color(red: 1.0, green: 0.62, blue: 0.04)         // #FF9F0A - iOS orange
        static let error = Color(red: 1.0, green: 0.27, blue: 0.23)           // #FF453A - iOS red
    }
    
    /// Text color hierarchy
    struct TextColors {
        static let primary = Color.white
        static let secondary = Color.white.opacity(0.85)
        static let tertiary = Color.white.opacity(0.65)
        static let quaternary = Color.white.opacity(0.45)
        static let disabled = Color.white.opacity(0.40)                       // Disabled state
    }
    
    /// Surface colors for cards and elevated elements
    struct SurfaceColors {
        static let base = Color.gray.opacity(0.10)                           // Base surface
        static let elevated = Color.white.opacity(0.14)                       // Elevated cards
        static let overlay = Color.white.opacity(0.18)                        // Modals/sheets
        
        // Legacy compatibility
        static let surface = base
        static let surfaceLight = Color.white.opacity(0.08)
        static let surfaceMedium = base
        static let surfaceElevated = elevated
    }
    
    /// Message bubble colors - Minimal like iMessage
    struct MessageColors {
        static let sent = Color(red: 0.04, green: 0.52, blue: 1.0)           // #0A84FF - Solid blue
        static let received = Color(red: 0.17, green: 0.17, blue: 0.18)      // #2C2C2E - Dark gray
        
        // Legacy compatibility
        static let sentStart = sent
        static let sentEnd = Color(red: 0.03, green: 0.42, blue: 0.85)       // Darker blue
    }
    
    // Legacy compatibility (will be removed)
    struct GradientColors {
        static let deepBlack = BackgroundColors.primary
        static let richBlack = BackgroundColors.secondary
        static let darkGray = BackgroundColors.tertiary
        static let deepPurple = BackgroundColors.primary
        static let richPurple = BackgroundColors.secondary
        static let deepBlue = BackgroundColors.tertiary
        static let deepNavyBlack = BackgroundColors.primary
        static let midnightBlue = BackgroundColors.secondary
        static let softBlue = BackgroundColors.tertiary
    }
    
    /// Primary gradient for backgrounds
    static let primaryGradient = LinearGradient(
        colors: [
            BackgroundColors.primary,
            BackgroundColors.secondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Layout Constants
    
    /// Fixed layout values for consistency
    struct Layout {
        // Padding
        static let screenPadding: CGFloat = 20                                // Standard screen edges
        static let screenPaddingIPad: CGFloat = 32                            // iPad screen edges
        static let cardPadding: CGFloat = 16                                  // Inside cards
        static let sectionSpacing: CGFloat = 32                               // Between major sections
        
        // Component sizes
        static let buttonHeight: CGFloat = 52                                 // Standard button
        static let buttonHeightSmall: CGFloat = 44                            // Small button
        static let iconButton: CGFloat = 44                                   // Icon-only button (min touch target)
        static let textFieldHeight: CGFloat = 52                              // Text input
        
        // Avatars
        static let avatarSmall: CGFloat = 40
        static let avatarMedium: CGFloat = 56
        static let avatarLarge: CGFloat = 80
        static let avatarXLarge: CGFloat = 120
        
        // Corner radius
        static let cornerRadiusSmall: CGFloat = 12
        static let cornerRadiusMedium: CGFloat = 16
        static let cornerRadiusLarge: CGFloat = 20
        static let cornerRadiusButton: CGFloat = 26                           // Pill-shaped buttons
        
        // iPad specific
        static let sidebarWidth: CGFloat = 340
        static let maxContentWidth: CGFloat = 680
        
        // Message bubbles
        static let messageBubbleMaxWidth: CGFloat = 280
        static let messageBubbleRadius: CGFloat = 18
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
    
    /// Spacing scale for consistent padding and margins (8pt grid)
    struct Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius (Deprecated - use Layout.cornerRadius*)
    
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
        static let slow: Double = 0.4
    }
    
    /// Simplified animation curves
    struct AnimationCurves {
        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)
        static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.65)
        static let easeInOut = Animation.easeInOut(duration: AnimationDuration.normal)
        static let easeOut = Animation.easeOut(duration: AnimationDuration.normal)
        
        // Specific interactions
        static let buttonPress = Animation.spring(response: 0.2, dampingFraction: 0.7)
        static let screenTransition = Animation.easeInOut(duration: AnimationDuration.slow)
        
        // Legacy compatibility
        static let componentAppearance = easeOut
    }
    
    // MARK: - Shadows
    
    /// Shadow configurations for depth
    struct Shadows {
        static let small = (color: Color.black.opacity(0.15), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: Color.black.opacity(0.2), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: Color.black.opacity(0.25), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(8))
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
