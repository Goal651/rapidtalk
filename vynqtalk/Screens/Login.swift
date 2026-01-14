//
//  Login.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI

struct LoginScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var wsM: WebSocketManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showModal: Bool = false
    @State private var modalTitle: String = ""
    @State private var modalDescription: String = ""
    @State private var isLoading: Bool = false
    
    func isValidEmail(_ email: String) -> Bool {
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
    
    var body: some View {
        ZStack {
            // AnimatedGradientBackground
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: AppTheme.Spacing.xl) {
                // Title
                VStack(spacing: AppTheme.Spacing.s) {
                    Text("Welcome Back")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.TextColors.secondary)
                    
                    Text("Login")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.TextColors.primary)
                }
                .padding(.top, AppTheme.Spacing.xxl)
                
                // Email Input
                CustomTextField(
                    label: "Email",
                    placeholder: "Enter your email",
                    text: $email,
                    keyboardType: .emailAddress,
                    validation: isValidEmail,
                    errorMessage: "Invalid email format"
                )
                .padding(.horizontal, AppTheme.Spacing.xl)
                
                // Password Input
                CustomTextField(
                    label: "Password",
                    placeholder: "Enter your password",
                    text: $password,
                    isSecure: true
                )
                .padding(.horizontal, AppTheme.Spacing.xl)
                
                // Login button
                CustomButton(
                    title: "Login",
                    style: .primary,
                    action: {
                        Task {
                            isLoading = true
                            let ok = await authVM.login(email: email, password: password)
                            isLoading = false
                            
                            if ok {
                                wsM.connect()
                            } else {
                                modalTitle = "Login Failed"
                                modalDescription = "Please check your email/password and try again."
                                withAnimation { showModal = true }
                            }
                        }
                    },
                    isLoading: isLoading,
                    isDisabled: email.isEmpty || password.isEmpty || !isValidEmail(email)
                )
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.m)
                
                // Forgot password
                Button(action: {}) {
                    Text("Forgot Password?")
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.TextColors.secondary)
                }
                .padding(.top, AppTheme.Spacing.s)
                
                Spacer()
            }
            
            // Modal overlay
            if showModal {
                ModalView(
                    title: modalTitle,
                    description: modalDescription,
                    onClose: { 
                        withAnimation {
                            showModal = false
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
}
