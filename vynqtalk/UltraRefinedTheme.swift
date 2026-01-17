//
//  UltraRefinedTheme.swift
//  vynqtalk
//
//  Ultra-Refined Design System - Maximum Calmness & Apple Quality
//  Final 20% noise reduction for portfolio-ready perfection
//

import SwiftUI

struct UltraTheme {
    
    // MARK: - Ultra-Calm Color Palette
    
    /// Backgrounds - Pure, minimal
    struct Backgrounds {
        static let primary = Color(red: 0.02, green: 0.02, blue: 0.04)
        static let surface = Color(red: 0.04, green: 0.04, blue: 0.06)
        
        // Single, perfect gradient
        static let gradient = LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.02, blue: 0.04),
                Color(red: 0.03, green: 0.03, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Glass - Minimal, perfect
    struct Glass {
        static let surface = Color.white.opacity(0.02)
        static let border = Color.white.opacity(0.04)
        static let elevated = Color.white.opacity(0.06)
    }
    
    /// Accent - Single, perfect blue
    struct Accent {
        static let primary = Color(red: 0.20, green: 0.60, blue: 1.0)
        static let soft = Color(red: 0.40, green: 0.70, blue: 1.0)
    }
    
    /// Text - Perfect hierarchy
    struct Text {
        static let primary = Color.white
        static let secondary = Color.white.opacity(0.70)
        static let tertiary = Color.white.opacity(0.50)
        static let quaternary = Color.white.opacity(0.30)
    }
    
    // MARK: - Perfect Layout
    
    struct Layout {
        // Spacing - 8pt grid perfection
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        
        // Radius - Perfect curves
        static let radius: CGFloat = 20
        static let radiusSmall: CGFloat = 12
        
        // Sizes - Apple standard
        static let buttonHeight: CGFloat = 50
        static let avatar: CGFloat = 50
        static let avatarLarge: CGFloat = 80
    }
    
    // MARK: - Perfect Typography
    
    struct Typography {
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    }
    
    // MARK: - Perfect Motion
    
    struct Motion {
        static let spring = Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let gentle = Animation.easeOut(duration: 0.4)
    }
}

// MARK: - Perfect Glass Modifiers

extension View {
    func ultraGlass() -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: UltraTheme.Layout.radius))
            .overlay(
                RoundedRectangle(cornerRadius: UltraTheme.Layout.radius)
                    .stroke(UltraTheme.Glass.border, lineWidth: 0.5)
            )
    }
    
    func ultraCard() -> some View {
        self
            .background(UltraTheme.Glass.surface, in: RoundedRectangle(cornerRadius: UltraTheme.Layout.radius))
    }
    
    func ultraShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 8, y: 2)
    }
}