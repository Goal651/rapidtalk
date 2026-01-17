//
//  UltraComponents.swift
//  vynqtalk
//
//  Ultra-Refined Components - Perfect Apple Quality
//  Minimal, focused, beautiful
//

import SwiftUI
import Foundation

// MARK: - Ultra Button

struct UltraButton: View {
    let title: String
    let action: () -> Void
    var style: Style = .primary
    
    enum Style {
        case primary, secondary
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(UltraTheme.Typography.body)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: UltraTheme.Layout.buttonHeight)
                .background(
                    Capsule()
                        .fill(backgroundFill)
                )
        }
        .buttonStyle(UltraButtonStyle())
    }
    
    private var backgroundFill: Color {
        switch style {
        case .primary:
            return UltraTheme.Accent.primary
        case .secondary:
            return UltraTheme.Glass.elevated
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return UltraTheme.Text.primary
        }
    }
}

struct UltraButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(UltraTheme.Motion.spring, value: configuration.isPressed)
    }
}

// MARK: - Ultra Text Field

struct UltraTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    
    @FocusState private var focused: Bool
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
            }
        }
        .font(UltraTheme.Typography.body)
        .foregroundColor(UltraTheme.Text.primary)
        .padding(.horizontal, UltraTheme.Layout.m)
        .frame(height: UltraTheme.Layout.buttonHeight)
        .focused($focused)
        .background(
            Capsule()
                .fill(UltraTheme.Glass.surface)
                .overlay(
                    Capsule()
                        .stroke(
                            focused ? UltraTheme.Accent.primary : UltraTheme.Glass.border,
                            lineWidth: focused ? 1 : 0.5
                        )
                )
        )
        .animation(UltraTheme.Motion.gentle, value: focused)
    }
}

// MARK: - Ultra Card

struct UltraCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(UltraTheme.Layout.l)
            .ultraGlass()
            .ultraShadow()
    }
}

// MARK: - Ultra Avatar

struct UltraAvatar: View {
    let url: URL?
    let size: CGFloat
    
    init(url: URL?, size: CGFloat = UltraTheme.Layout.avatar) {
        self.url = url
        self.size = size
    }
    
    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Circle()
                .fill(UltraTheme.Glass.elevated)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4, weight: .medium))
                        .foregroundColor(UltraTheme.Text.secondary)
                )
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Ultra Loading

struct UltraLoading: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: UltraTheme.Accent.primary))
            .scaleEffect(1.2)
    }
}

// MARK: - Ultra Navigation Bar

struct UltraNavigationBar<Leading: View, Trailing: View>: View {
    let title: String
    let leading: Leading
    let trailing: Trailing
    
    init(
        title: String,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack {
            leading
            
            Spacer()
            
            Text(title)
                .font(UltraTheme.Typography.title)
                .foregroundColor(UltraTheme.Text.primary)
            
            Spacer()
            
            trailing
        }
        .padding(.horizontal, UltraTheme.Layout.l)
        .padding(.vertical, UltraTheme.Layout.m)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Ultra Floating Action Button

struct UltraFAB: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(UltraTheme.Accent.primary)
                        .shadow(
                            color: UltraTheme.Accent.primary.opacity(0.3),
                            radius: 8,
                            y: 2
                        )
                )
        }
        .buttonStyle(UltraButtonStyle())
    }
}

// MARK: - Ultra Status Indicator

struct UltraStatusIndicator: View {
    let isOnline: Bool
    
    var body: some View {
        Circle()
            .fill(isOnline ? Color.green : UltraTheme.Text.quaternary)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Ultra Divider

struct UltraDivider: View {
    var body: some View {
        Rectangle()
            .fill(UltraTheme.Glass.border)
            .frame(height: 0.5)
    }
}

// MARK: - Ultra Empty State

struct UltraEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: UltraTheme.Layout.l) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(UltraTheme.Text.quaternary)
            
            VStack(spacing: UltraTheme.Layout.s) {
                Text(title)
                    .font(UltraTheme.Typography.title)
                    .foregroundColor(UltraTheme.Text.primary)
                
                Text(subtitle)
                    .font(UltraTheme.Typography.caption)
                    .foregroundColor(UltraTheme.Text.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(UltraTheme.Layout.xl)
    }
}