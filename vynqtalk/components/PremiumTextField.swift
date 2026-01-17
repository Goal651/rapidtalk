//
//  PremiumTextField.swift
//  vynqtalk
//
//  Premium Text Field Component - Apple Quality Design
//  Glass effects with smooth focus animations
//

import SwiftUI

struct PremiumTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var icon: String? = nil
    var trailingIcon: String? = nil
    var trailingAction: (() -> Void)? = nil
    var validation: ((String) -> Bool)? = nil
    var errorMessage: String? = nil
    
    @FocusState private var isFocused: Bool
    @State private var showError: Bool = false
    @State private var hasValidated: Bool = false
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacing12) {
            // Floating label
            if !label.isEmpty {
                Text(label)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(labelColor)
                    .padding(.horizontal, AppTheme.Layout.screenPadding)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
            }
            
            // Input container with glass effect
            HStack(spacing: AppTheme.Layout.spacing16) {
                // Leading icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 24)
                        .scaleEffect(isFocused ? 1.1 : 1.0)
                }
                
                // Text field
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.TextColors.primary)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .focused($isFocused)
                .onChange(of: text) { _ in
                    validateIfNeeded()
                }
                
                // Trailing content
                trailingContent
            }
            .padding(.horizontal, AppTheme.Layout.spacing20)
            .padding(.vertical, AppTheme.Layout.spacing16)
            .background(backgroundView)
            .overlay(overlayView)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusLarge))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                y: shadowY
            )
            .padding(.horizontal, AppTheme.Layout.screenPadding)
            .scaleEffect(appeared ? 1 : 0.95)
            .opacity(appeared ? 1 : 0)
            
            // Error message
            if showError, let errorMessage = errorMessage {
                errorMessageView(errorMessage)
            }
        }
        .animation(AppTheme.Animations.spring, value: isFocused)
        .animation(AppTheme.Animations.spring, value: showError)
        .animation(AppTheme.Animations.cardAppear, value: appeared)
        .onAppear {
            withAnimation(AppTheme.Animations.cardAppear.delay(0.1)) {
                appeared = true
            }
        }
        .onChange(of: isFocused) { focused in
            if !focused {
                hasValidated = true
                validateIfNeeded()
            }
        }
    }
    
    // MARK: - Trailing Content
    
    @ViewBuilder
    private var trailingContent: some View {
        if let trailingIcon = trailingIcon, let action = trailingAction {
            Button(action: action) {
                Image(systemName: trailingIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
            .buttonStyle(GlassButtonStyle())
        } else if !text.isEmpty && isFocused && !isSecure {
            Button(action: {
                withAnimation(AppTheme.Animations.springSnappy) {
                    text = ""
                    showError = false
                    hasValidated = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
            .transition(.scale.combined(with: .opacity))
            .buttonStyle(GlassButtonStyle())
        }
    }
    
    // MARK: - Background & Overlay
    
    @ViewBuilder
    private var backgroundView: some View {
        if showError {
            AppTheme.GlassMaterials.thin
                .overlay(
                    Color.red.opacity(0.1)
                )
        } else {
            AppTheme.GlassMaterials.thin
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusLarge)
            .stroke(borderGradient, lineWidth: borderWidth)
    }
    
    private var borderGradient: LinearGradient {
        if showError {
            return LinearGradient(
                colors: [
                    AppTheme.AccentColors.error.opacity(0.6),
                    AppTheme.AccentColors.error.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isFocused {
            return LinearGradient(
                colors: [
                    AppTheme.AccentColors.primary.opacity(0.6),
                    AppTheme.AccentColors.primary.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Colors
    
    private var labelColor: Color {
        if showError {
            return AppTheme.AccentColors.error
        } else if isFocused {
            return AppTheme.AccentColors.primary
        } else {
            return AppTheme.TextColors.secondary
        }
    }
    
    private var iconColor: Color {
        if showError {
            return AppTheme.AccentColors.error
        } else if isFocused {
            return AppTheme.AccentColors.primary
        } else {
            return AppTheme.TextColors.tertiary
        }
    }
    
    private var borderWidth: CGFloat {
        return (isFocused || showError) ? 1.5 : 0.5
    }
    
    private var shadowColor: Color {
        if showError {
            return AppTheme.AccentColors.error.opacity(0.2)
        } else if isFocused {
            return AppTheme.AccentColors.primary.opacity(0.2)
        } else {
            return Color.black.opacity(0.05)
        }
    }
    
    private var shadowRadius: CGFloat {
        return (isFocused || showError) ? 12 : 6
    }
    
    private var shadowY: CGFloat {
        return (isFocused || showError) ? 4 : 2
    }
    
    // MARK: - Error Message View
    
    private func errorMessageView(_ message: String) -> some View {
        HStack(spacing: AppTheme.Layout.spacing8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
            
            Text(message)
                .font(AppTheme.Typography.caption)
        }
        .foregroundColor(AppTheme.AccentColors.error)
        .padding(.horizontal, AppTheme.Layout.screenPadding)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Validation
    
    private func validateIfNeeded() {
        guard hasValidated || !isFocused else { return }
        
        if let validation = validation {
            showError = !text.isEmpty && !validation(text)
        } else {
            showError = false
        }
    }
}

// MARK: - Premium Search Field

struct PremiumSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    var onSubmit: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: AppTheme.Layout.spacing12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isFocused ? AppTheme.AccentColors.primary : AppTheme.TextColors.tertiary)
                .scaleEffect(isFocused ? 1.1 : 1.0)
            
            TextField(placeholder, text: $text)
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(AppTheme.TextColors.primary)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }
            
            if !text.isEmpty {
                Button(action: {
                    withAnimation(AppTheme.Animations.springSnappy) {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.TextColors.tertiary)
                }
                .transition(.scale.combined(with: .opacity))
                .buttonStyle(GlassButtonStyle())
            }
        }
        .padding(.horizontal, AppTheme.Layout.spacing20)
        .padding(.vertical, AppTheme.Layout.spacing16)
        .background(AppTheme.GlassMaterials.thin)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusLarge)
                .stroke(borderGradient, lineWidth: borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusLarge))
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            y: shadowY
        )
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(AppTheme.Animations.cardAppear.delay(0.2)) {
                appeared = true
            }
        }
        .animation(AppTheme.Animations.spring, value: isFocused)
    }
    
    private var borderGradient: LinearGradient {
        if isFocused {
            return LinearGradient(
                colors: [
                    AppTheme.AccentColors.primary.opacity(0.6),
                    AppTheme.AccentColors.primary.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var borderWidth: CGFloat {
        return isFocused ? 1.5 : 0.5
    }
    
    private var shadowColor: Color {
        return isFocused ? AppTheme.AccentColors.primary.opacity(0.2) : Color.black.opacity(0.05)
    }
    
    private var shadowRadius: CGFloat {
        return isFocused ? 12 : 6
    }
    
    private var shadowY: CGFloat {
        return isFocused ? 4 : 2
    }
}

// MARK: - Glass Button Style (for internal buttons)

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppTheme.Animations.buttonPress, value: configuration.isPressed)
    }
}