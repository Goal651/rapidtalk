//
//  CustomTextField.swift
//  vynqtalk
//
//  Reusable text field component with validation and animations
//

import SwiftUI

struct CustomTextField: View {
    
    // MARK: - Properties
    
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var validation: ((String) -> Bool)? = nil
    var errorMessage: String? = nil
    var accessibilityHint: String? = nil
    
    // MARK: - State
    
    @FocusState private var isFocused: Bool
    @State private var showError: Bool = false
    @State private var hasValidated: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            // Label
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(labelColor)
                .animation(AppTheme.AnimationCurves.easeInOut, value: isFocused)
            
            // Input Field
            HStack(spacing: AppTheme.Spacing.s) {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.TextColors.primary)
                        .keyboardType(keyboardType)
                        .focused($isFocused)
                        .onChange(of: text) { _ in
                            validateIfNeeded()
                        }
                        .accessibilityLabel(label)
                        .accessibilityHint(accessibilityHint ?? "Secure text entry for \(label.lowercased())")
                } else {
                    TextField(placeholder, text: $text)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.TextColors.primary)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .focused($isFocused)
                        .onChange(of: text) { _ in
                            validateIfNeeded()
                        }
                        .accessibilityLabel(label)
                        .accessibilityHint(accessibilityHint ?? "Text entry for \(label.lowercased())")
                        .accessibilityValue(text.isEmpty ? "Empty" : text)
                }
                
                // Clear button
                if !text.isEmpty && isFocused && !isSecure {
                    Button(action: {
                        text = ""
                        showError = false
                        hasValidated = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.TextColors.tertiary)
                            .font(.system(size: 16))
                    }
                    .accessibilityLabel("Clear \(label.lowercased())")
                    .accessibilityHint("Clears the text in the \(label.lowercased()) field")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(AppTheme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                    .fill(AppTheme.SurfaceColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.m)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(isFocused ? 1.01 : 1.0)
            .shadow(
                color: shadowColor,
                radius: isFocused ? 8 : 0,
                x: 0,
                y: 0
            )
            .animation(AppTheme.AnimationCurves.easeInOut, value: isFocused)
            .animation(AppTheme.AnimationCurves.easeInOut, value: showError)
            
            // Error Message
            if showError, let errorMessage = errorMessage {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(AppTheme.Typography.caption)
                }
                .foregroundColor(AppTheme.AccentColors.error)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: AppTheme.AnimationDuration.fast), value: showError)
        .onChange(of: isFocused) { focused in
            if !focused {
                hasValidated = true
                validateIfNeeded()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var labelColor: Color {
        if showError {
            return AppTheme.AccentColors.error
        }
        if isFocused {
            return AppTheme.AccentColors.primary
        }
        return AppTheme.TextColors.secondary
    }
    
    private var borderColor: Color {
        if showError {
            return AppTheme.AccentColors.error.opacity(0.6)
        }
        if isFocused {
            return AppTheme.AccentColors.primary.opacity(0.6)
        }
        return AppTheme.TextColors.tertiary
    }
    
    private var shadowColor: Color {
        if showError {
            return AppTheme.AccentColors.error.opacity(0.3)
        }
        if isFocused {
            return AppTheme.AccentColors.primary.opacity(0.3)
        }
        return Color.clear
    }
    
    // MARK: - Methods
    
    private func validateIfNeeded() {
        guard hasValidated || !isFocused else { return }
        
        if let validation = validation {
            showError = !text.isEmpty && !validation(text)
        } else {
            showError = false
        }
    }
}

// MARK: - Preview

struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.primaryGradient
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.l) {
                CustomTextField(
                    label: "Email",
                    placeholder: "Enter your email",
                    text: .constant(""),
                    keyboardType: .emailAddress
                )
                
                CustomTextField(
                    label: "Password",
                    placeholder: "Enter your password",
                    text: .constant(""),
                    isSecure: true
                )
                
                CustomTextField(
                    label: "Email with Error",
                    placeholder: "Enter your email",
                    text: .constant("invalid"),
                    keyboardType: .emailAddress,
                    validation: { email in
                        email.contains("@") && email.contains(".")
                    },
                    errorMessage: "Invalid email format"
                )
                
                CustomTextField(
                    label: "Name",
                    placeholder: "Enter your name",
                    text: .constant("John Doe")
                )
            }
            .padding(AppTheme.Spacing.l)
        }
    }
}
