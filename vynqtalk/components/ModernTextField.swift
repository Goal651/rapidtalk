//
//  ModernTextField.swift
//  vynqtalk
//
//  Premium text field component with simplified animations
//

import SwiftUI

struct ModernTextField: View {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Label
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.secondary)
                .padding(.horizontal, AppTheme.Layout.screenPadding)
            
            // Input Container
            HStack(spacing: 14) {
                // Leading icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(isFocused ? AppTheme.AccentColors.primary : AppTheme.TextColors.tertiary)
                        .frame(width: 20)
                }
                
                // Text field
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .focused($isFocused)
                .onChange(of: text) { _ in
                    validateIfNeeded()
                }
                
                // Trailing icon/action
                if let trailingIcon = trailingIcon, let action = trailingAction {
                    Button(action: action) {
                        Image(systemName: trailingIcon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppTheme.TextColors.tertiary)
                    }
                } else if !text.isEmpty && isFocused && !isSecure {
                    Button(action: {
                        text = ""
                        showError = false
                        hasValidated = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppTheme.TextColors.tertiary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusMedium)
                    .fill(AppTheme.SurfaceColors.base)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusMedium)
                            .stroke(
                                showError ? AppTheme.AccentColors.error.opacity(0.6) :
                                isFocused ? AppTheme.AccentColors.primary.opacity(0.5) : Color.clear,
                                lineWidth: isFocused || showError ? 1.5 : 0
                            )
                    )
            )
            .padding(.horizontal, AppTheme.Layout.screenPadding)
            
            // Error Message
            if showError, let errorMessage = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(AppTheme.AccentColors.error)
                .padding(.horizontal, AppTheme.Layout.screenPadding)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(AppTheme.AnimationCurves.spring, value: isFocused)
        .animation(AppTheme.AnimationCurves.spring, value: showError)
        .onChange(of: isFocused) { focused in
            if !focused {
                hasValidated = true
                validateIfNeeded()
            }
        }
    }
    
    private func validateIfNeeded() {
        guard hasValidated || !isFocused else { return }
        
        if let validation = validation {
            showError = !text.isEmpty && !validation(text)
        } else {
            showError = false
        }
    }
}