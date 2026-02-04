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
    @State private var appeared = false
    @State private var showPassword = false
    
    func isValidEmail(_ email: String) -> Bool {
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
    
    var body: some View {
        ZStack {
            // Deep black background like onboarding
            AppTheme.GradientColors.deepBlack
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header with floating animation
                    VStack(spacing: 16) {
                        // 3D Welcome illustration
                        welcomeIllustration
                            .frame(height: 200)
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.8)
                            .offset(y: appeared ? 0 : 30)
                        
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        
                        Text("Sign in to continue your conversations")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .opacity(appeared ? 1 : 0)
                    }
                    .padding(.top, 60)
                    
                    // Form with modern cards
                    VStack(spacing: 20) {
                        // Email Field
                        ModernTextField(
                            label: "Email",
                            placeholder: "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress,
                            icon: "envelope.fill",
                            validation: isValidEmail,
                            errorMessage: "Invalid email format"
                        )
                        
                        // Password Field
                        ModernTextField(
                            label: "Password",
                            placeholder: "Enter your password",
                            text: $password,
                            isSecure: !showPassword,
                            icon: "lock.fill",
                            trailingIcon: showPassword ? "eye.slash.fill" : "eye.fill",
                            trailingAction: { showPassword.toggle() }
                        )
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button(action: {}) {
                                Text("Forgot Password?")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.AccentColors.primary)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    
                    // Login Button
                    ModernButton(
                        title: "Sign In",
                        style: .primary,
                        isLoading: isLoading,
                        isDisabled: email.isEmpty || password.isEmpty || !isValidEmail(email)
                    ) {
                        Task {
                            isLoading = true
                            let response = await authVM.login(email: email, password: password)
                            isLoading = false
                            
                            if response.1{
                                wsM.connect()
                            } else {
                                modalTitle = "Login Failed"
                                modalDescription = response.0
                                withAnimation { showModal = true }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Modal overlay
            if showModal {
                ModernModal(
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
                CustomBackButton()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        )
    }
    
    // MARK: - Welcome Illustration
    
    @State private var floatingOffset: CGFloat = 0
    
    @ViewBuilder
    private var welcomeIllustration: some View {
        ZStack {
            // Base platform
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.AccentColors.primary.opacity(0.3),
                            AppTheme.AccentColors.primary.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 140, height: 35)
                .shadow(color: AppTheme.AccentColors.primary.opacity(0.2), radius: 15, y: 8)
                .offset(y: 40)
                .offset(y: floatingOffset * 0.5)
            
            // Floating login card
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.AccentColors.primary, AppTheme.AccentColors.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 60)
                .overlay(
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                )
                .shadow(color: AppTheme.AccentColors.primary.opacity(0.4), radius: 15, y: 8)
                .rotation3DEffect(.degrees(-8), axis: (x: 0, y: 1, z: 0))
                .offset(y: floatingOffset)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatingOffset = -10
            }
        }
    }
}
