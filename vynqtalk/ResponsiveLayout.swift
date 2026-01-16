//
//  ResponsiveLayout.swift
//  vynqtalk
//
//  Responsive layout utilities for adaptive sizing across iOS devices
//

import SwiftUI

/// Device type for responsive design
enum DeviceType {
    case iPhone
    case iPad
    
    static var current: DeviceType {
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
    }
}

/// Device size categories for responsive design
enum DeviceSizeCategory {
    case compact    // iPhone SE, iPhone 12/13 mini
    case regular    // iPhone 12/13/14/15
    case large      // iPhone 14/15 Plus, Pro Max
    case tablet     // iPad
    
    /// Determine size category from screen width
    static func from(width: CGFloat) -> DeviceSizeCategory {
        if DeviceType.current == .iPad {
            return .tablet
        }
        
        switch width {
        case ..<375:
            return .compact
        case 375..<430:
            return .regular
        default:
            return .large
        }
    }
}

/// Responsive spacing values that adapt to screen size
struct ResponsiveSpacing {
    let screenWidth: CGFloat
    let sizeCategory: DeviceSizeCategory
    
    init(screenWidth: CGFloat) {
        self.screenWidth = screenWidth
        self.sizeCategory = DeviceSizeCategory.from(width: screenWidth)
    }
    
    /// Horizontal padding - fixed values
    var horizontalPadding: CGFloat {
        sizeCategory == .tablet ? AppTheme.Layout.screenPaddingIPad : AppTheme.Layout.screenPadding
    }
    
    /// Content max width for readability
    var contentMaxWidth: CGFloat {
        sizeCategory == .tablet ? AppTheme.Layout.maxContentWidth : screenWidth
    }
    
    /// Vertical spacing between major sections
    var sectionSpacing: CGFloat {
        switch sizeCategory {
        case .compact:
            return AppTheme.Spacing.l
        case .regular:
            return AppTheme.Layout.sectionSpacing
        case .large:
            return AppTheme.Layout.sectionSpacing
        case .tablet:
            return 40
        }
    }
    
    /// Top padding for main content
    var topPadding: CGFloat {
        switch sizeCategory {
        case .compact:
            return AppTheme.Spacing.m
        case .regular:
            return AppTheme.Spacing.l
        case .large:
            return AppTheme.Spacing.l
        case .tablet:
            return AppTheme.Layout.sectionSpacing
        }
    }
    
    /// Bottom padding for main content
    var bottomPadding: CGFloat {
        switch sizeCategory {
        case .compact:
            return AppTheme.Spacing.l
        case .regular:
            return AppTheme.Layout.sectionSpacing
        case .large:
            return AppTheme.Layout.sectionSpacing
        case .tablet:
            return 40
        }
    }
    
    /// Spacing for form elements
    var formSpacing: CGFloat {
        switch sizeCategory {
        case .compact:
            return AppTheme.Spacing.m
        case .regular:
            return AppTheme.Spacing.l
        case .large:
            return AppTheme.Spacing.l
        case .tablet:
            return AppTheme.Layout.sectionSpacing
        }
    }
    
    /// Icon size scaling
    var iconScale: CGFloat {
        switch sizeCategory {
        case .compact:
            return 0.9
        case .regular:
            return 1.0
        case .large:
            return 1.0
        case .tablet:
            return 1.1
        }
    }
    
    /// Check if device is iPad
    var isTablet: Bool {
        return sizeCategory == .tablet
    }
    
    /// User list width for split view (iPad only)
    var userListWidth: CGFloat {
        return AppTheme.Layout.sidebarWidth
    }
    
    /// Chat width for split view (iPad only)
    var chatWidth: CGFloat {
        return screenWidth - AppTheme.Layout.sidebarWidth
    }
}

/// View modifier for responsive layout
struct ResponsiveLayoutModifier: ViewModifier {
    let geometry: GeometryProxy
    
    var spacing: ResponsiveSpacing {
        ResponsiveSpacing(screenWidth: geometry.size.width)
    }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: spacing.contentMaxWidth)
    }
}

extension View {
    /// Apply responsive layout constraints
    func responsiveLayout(_ geometry: GeometryProxy) -> some View {
        self.modifier(ResponsiveLayoutModifier(geometry: geometry))
    }
    
    /// Get responsive spacing for the current screen size
    func responsiveSpacing(for width: CGFloat) -> ResponsiveSpacing {
        ResponsiveSpacing(screenWidth: width)
    }
}

/// Orientation-aware container
struct OrientationAwareContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let content: (Bool) -> Content
    
    var isLandscape: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        content(isLandscape)
    }
}

extension View {
    /// Wrap view in orientation-aware container
    func orientationAware<Content: View>(@ViewBuilder content: @escaping (Bool) -> Content) -> some View {
        OrientationAwareContainer { isLandscape in
            content(isLandscape)
        }
    }
}
