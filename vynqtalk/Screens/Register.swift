//
//  Register.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI

struct RegisterScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showSuccessModal: Bool = false
    @State private var isLoading: Bool = false
    
    @AppStorage("loggedIn") var loggedIn: Bool = false
    
    // Email validation function
    func isValidEmail(_ email: String) -> Bool {
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
    
    // Password match validation
    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    // Form validation
    var isFormValid: Bool {
        !name.isEmpty && isValidEmail(email) && !password.isEmpty && passwordsMatch
    }
    
    var body: some View {
        ZStack {
            // Animated Gradient Background
            AnimatedGradientBackground(configuration: .primary)
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.l) {
                    // Title Section
                    VStack(spacing: AppTheme.Spacing.s) {
                        Text("Create your account")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.TextColors.secondary)
                        
                        Text("Register")
                            .font(AppTheme.Typography.largeTitle)
                            .foregroundColor(AppTheme.TextColors.primary)
                    }
                    .padding(.top, AppTheme.Spacing.xxl)
                    
                    // Name Field
                    CustomTextField(
                        label: "Name",
                        placeholder: "Enter your name",
                        text: $name,
                        keyboardType: .default
                    )
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    
                    // Email Field with Validation
                    CustomTextField(
                        label: "Email",
                        placeholder: "Enter your email",
                        text: $email,
                        keyboardType: .emailAddress,
                        validation: isValidEmail,
                        errorMessage: "Invalid email format"
                    )
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    
                    // Password Field
                    CustomTextField(
                        label: "Password",
                        placeholder: "Enter password",
                        text: $password,
                        isSecure: true
                    )
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    
                    // Confirm Password Field with Match Validation
                    CustomTextField(
                        label: "Confirm Password",
                        placeholder: "Re-enter password",
                        text: $confirmPassword,
                        isSecure: true,
                        validation: { _ in passwordsMatch },
                        errorMessage: "Passwords do not match"
                    )
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    
                    // Register Button
                    CustomButton(
                        title: "Register",
                        style: .primary,
                        action: handleRegister,
                        isLoading: isLoading,
                        isDisabled: !isFormValid
                    )
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.m)
                    
                    Spacer()
                }
            }
            
            // Success Modal
            if showSuccessModal {
                RegisterSuccessModal(
                    userName: name,
                    onDismiss: {
                        withAnimation(AppTheme.AnimationCurves.easeOut) {
                            showSuccessModal = false
                        }
                        // Navigate to Home Screen after modal dismisses
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            nav.reset(to: .main)
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        )
    }
    
    // MARK: - Actions
    
    private func handleRegister() {
        isLoading = true
        
        Task {
            let success = await authVM.register(email: email, name: name, password: password)
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    loggedIn = true
                    withAnimation(AppTheme.AnimationCurves.easeOut) {
                        showSuccessModal = true
                    }
                }
                // Note: Error handling would show a toast notification
                // For now, we just stop loading on failure
            }
        }
    }
}
