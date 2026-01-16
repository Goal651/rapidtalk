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
    @State private var appeared = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
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
            // Deep black background like onboarding
            AppTheme.GradientColors.deepBlack
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header with floating animation
                    VStack(spacing: 16) {
                        // 3D Register illustration
                        registerIllustration
                            .frame(height: 180)
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.8)
                            .offset(y: appeared ? 0 : 30)
                        
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                        
                        Text("Join VynqTalk and start connecting\nwith friends around the world")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .opacity(appeared ? 1 : 0)
                    }
                    .padding(.top, 40)
                    
                    // Form with modern cards
                    VStack(spacing: 20) {
                        // Name Field
                        ModernTextField(
                            label: "Full Name",
                            placeholder: "Enter your full name",
                            text: $name,
                            icon: "person.fill"
                        )
                        
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
                            placeholder: "Create a password",
                            text: $password,
                            isSecure: !showPassword,
                            icon: "lock.fill",
                            trailingIcon: showPassword ? "eye.slash.fill" : "eye.fill",
                            trailingAction: { showPassword.toggle() }
                        )
                        
                        // Confirm Password Field
                        ModernTextField(
                            label: "Confirm Password",
                            placeholder: "Re-enter your password",
                            text: $confirmPassword,
                            isSecure: !showConfirmPassword,
                            icon: "lock.fill",
                            trailingIcon: showConfirmPassword ? "eye.slash.fill" : "eye.fill",
                            trailingAction: { showConfirmPassword.toggle() },
                            validation: { _ in passwordsMatch },
                            errorMessage: "Passwords do not match"
                        )
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    
                    // Register Button
                    ModernButton(
                        title: "Create Account",
                        style: .primary,
                        isLoading: isLoading,
                        isDisabled: !isFormValid,
                        icon: "person.badge.plus"
                    ) {
                        handleRegister()
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                    
                    // Terms text
                    Text("By creating an account, you agree to our\n**Terms of Service** and **Privacy Policy**")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(appeared ? 1 : 0)
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Success Modal
            if showSuccessModal {
                ModernSuccessModal(
                    userName: name,
                    onDismiss: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
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
                ModernBackButton()
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
    
    // MARK: - Register Illustration
    
    @State private var floatingOffset: CGFloat = 0
    
    @ViewBuilder
    private var registerIllustration: some View {
        ZStack {
            // Base platform
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.AccentColors.online.opacity(0.3),
                            AppTheme.AccentColors.online.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 30)
                .shadow(color: AppTheme.AccentColors.online.opacity(0.2), radius: 12, y: 6)
                .offset(y: 35)
                .offset(y: floatingOffset * 0.5)
            
            // Floating user cards
            HStack(spacing: -10) {
                // Left card
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.AccentColors.primary, AppTheme.AccentColors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 45)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: AppTheme.AccentColors.primary.opacity(0.4), radius: 12, y: 6)
                    .rotation3DEffect(.degrees(-15), axis: (x: 0, y: 1, z: 0))
                    .offset(y: floatingOffset * 1.2)
                
                // Center card (main)
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.AccentColors.online, AppTheme.AccentColors.online.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 55)
                    .overlay(
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: AppTheme.AccentColors.online.opacity(0.4), radius: 15, y: 8)
                    .offset(y: floatingOffset)
                    .zIndex(1)
                
                // Right card
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "EC4899"), Color(hex: "EC4899").opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 45)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color(hex: "EC4899").opacity(0.4), radius: 12, y: 6)
                    .rotation3DEffect(.degrees(15), axis: (x: 0, y: 1, z: 0))
                    .offset(y: floatingOffset * 0.8)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatingOffset = -8
            }
        }
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
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showSuccessModal = true
                    }
                }
                // Note: Error handling would show a toast notification
                // For now, we just stop loading on failure
            }
        }
    }
}

// MARK: - Modern Success Modal

struct ModernSuccessModal: View {
    let userName: String
    let onDismiss: () -> Void
    @State private var appeared = false
    @State private var confettiOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Modal Card
            VStack(spacing: 32) {
                // Success Animation
                ZStack {
                    // Confetti particles
                    ForEach(0..<8) { index in
                        Circle()
                            .fill(confettiColors[index % confettiColors.count])
                            .frame(width: 8, height: 8)
                            .offset(
                                x: cos(Double(index) * .pi / 4) * (appeared ? 60 : 0),
                                y: sin(Double(index) * .pi / 4) * (appeared ? 60 : 0)
                            )
                            .opacity(appeared ? 0 : 1)
                    }
                    
                    // Success icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80, weight: .semibold))
                        .foregroundColor(AppTheme.AccentColors.online)
                        .scaleEffect(appeared ? 1 : 0.3)
                        .rotationEffect(.degrees(appeared ? 0 : -180))
                }
                .frame(height: 120)
                
                // Content
                VStack(spacing: 16) {
                    Text("Welcome to VynqTalk!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Hi **\(userName)**! Your account has been created successfully. You're ready to start connecting with friends.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                
                // Continue Button
                ModernButton(
                    title: "Let's Go!",
                    style: .primary,
                    icon: "arrow.right"
                ) {
                    onDismiss()
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 40)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(AppTheme.GradientColors.deepBlack)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppTheme.AccentColors.online.opacity(0.3),
                                        AppTheme.AccentColors.primary.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: AppTheme.AccentColors.online.opacity(0.2),
                        radius: 40,
                        y: 20
                    )
            )
            .padding(.horizontal, 32)
            .scaleEffect(appeared ? 1 : 0.7)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }
    
    private let confettiColors: [Color] = [
        AppTheme.AccentColors.primary,
        AppTheme.AccentColors.online,
        Color(hex: "EC4899"),  // Pink
        Color(hex: "FB923C"),  // Orange
        Color(hex: "8B5CF6"),  // Purple
        AppTheme.AccentColors.warning
    ]
}
