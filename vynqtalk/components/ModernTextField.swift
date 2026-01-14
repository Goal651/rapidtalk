//
//  ModernTextField.swift
//  vynqtalk
//
//  Modern text field component matching onboarding design
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
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 24)
            
            // Input Container
            HStack(spacing: 16) {
                // Leading icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isFocused ? AppTheme.AccentColors.primary : .white.opacity(0.5))
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
                .foregroundColor(.white)
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
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else if !text.isEmpty && isFocused && !isSecure {
                    Button(action: {
                        text = ""
                        showError = false
                        hasValidated = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(isFocused ? 0.12 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                showError ? AppTheme.AccentColors.error.opacity(0.6) :
                                isFocused ? AppTheme.AccentColors.primary.opacity(0.6) : .white.opacity(0.2),
                                lineWidth: showError || isFocused ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .shadow(
                color: showError ? AppTheme.AccentColors.error.opacity(0.2) :
                       isFocused ? AppTheme.AccentColors.primary.opacity(0.2) : .clear,
                radius: isFocused ? 12 : 0,
                y: isFocused ? 4 : 0
            )
            .padding(.horizontal, 24)
            
            // Error Message
            if showError, let errorMessage = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundColor(AppTheme.AccentColors.error)
                .padding(.horizontal, 24)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showError)
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