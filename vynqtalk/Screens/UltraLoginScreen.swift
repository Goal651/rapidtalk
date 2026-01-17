//
//  UltraLoginScreen.swift
//  vynqtalk
//
//  Ultra-Refined Login Screen - Perfect Simplicity
//  Zero distractions, maximum focus
//

import SwiftUI
import Foundation

struct UltraLoginScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var appeared = false
    
    @FocusState private var emailFocused: Bool
    @FocusState private var passwordFocused: Bool
    
    var body: some View {
        ZStack {
            // Perfect background
            UltraTheme.Backgrounds.gradient
                .ignoresSafeArea()
            
            VStack(spacing: UltraTheme.Layout.xl) {
                Spacer()
                
                // Perfect logo area
                ultraLogo
                
                // Perfect form
                ultraForm
                
                // Perfect actions
                ultraActions
                
                Spacer()
            }
            .padding(.horizontal, UltraTheme.Layout.xl)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(UltraTheme.Motion.gentle) {
                appeared = true
            }
        }
    }
    
    // MARK: - Perfect Logo
    
    private var ultraLogo: some View {
        VStack(spacing: UltraTheme.Layout.m) {
            // Perfect app icon
            Circle()
                .fill(UltraTheme.Accent.primary)
                .frame(width: UltraTheme.Layout.avatarLarge, height: UltraTheme.Layout.avatarLarge)
                .overlay(
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                )
                .ultraShadow()
            
            // Perfect title
            VStack(spacing: UltraTheme.Layout.xs) {
                Text("VynqTalk")
                    .font(UltraTheme.Typography.largeTitle)
                    .foregroundColor(UltraTheme.Text.primary)
                
                Text("Stay connected")
                    .font(UltraTheme.Typography.caption)
                    .foregroundColor(UltraTheme.Text.tertiary)
            }
        }
    }
    
    // MARK: - Perfect Form
    
    private var ultraForm: some View {
        VStack(spacing: UltraTheme.Layout.m) {
            UltraTextField(title: "Email", text: $email)
                .focused($emailFocused)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            
            UltraTextField(title: "Password", text: $password, isSecure: true)
                .focused($passwordFocused)
                .textContentType(.password)
        }
    }
    
    // MARK: - Perfect Actions
    
    private var ultraActions: some View {
        VStack(spacing: UltraTheme.Layout.m) {
            // Perfect login button
            UltraButton(title: isLoading ? "Signing in..." : "Sign In") {
                signIn()
            }
            .disabled(isLoading || !isFormValid)
            .opacity(isFormValid ? 1 : 0.6)
            
            // Perfect register link
            Button(action: {
                nav.push(.register)
            }) {
                HStack(spacing: UltraTheme.Layout.xs) {
                    Text("Don't have an account?")
                        .foregroundColor(UltraTheme.Text.tertiary)
                    
                    Text("Sign Up")
                        .foregroundColor(UltraTheme.Accent.primary)
                }
                .font(UltraTheme.Typography.caption)
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func signIn() {
        guard isFormValid else { return }
        
        isLoading = true
        emailFocused = false
        passwordFocused = false
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        Task {
            let success = await authVM.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            
            await MainActor.run {
                isLoading = false
                
                if !success {
                    // Gentle error feedback
                    let errorGenerator = UINotificationFeedbackGenerator()
                    errorGenerator.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Ultra Register Screen

struct UltraRegisterScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Perfect background
            UltraTheme.Backgrounds.gradient
                .ignoresSafeArea()
            
            VStack(spacing: UltraTheme.Layout.xl) {
                // Perfect header
                UltraNavigationBar(title: "Create Account") {
                    Button(action: { nav.pop() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(UltraTheme.Accent.primary)
                    }
                }
                
                Spacer()
                
                // Perfect form
                VStack(spacing: UltraTheme.Layout.m) {
                    UltraTextField(title: "Full Name", text: $name)
                        .textContentType(.name)
                    
                    UltraTextField(title: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    UltraTextField(title: "Password", text: $password, isSecure: true)
                        .textContentType(.newPassword)
                }
                
                // Perfect action
                UltraButton(title: isLoading ? "Creating Account..." : "Create Account") {
                    register()
                }
                .disabled(isLoading || !isFormValid)
                .opacity(isFormValid ? 1 : 0.6)
                
                Spacer()
            }
            .padding(.horizontal, UltraTheme.Layout.xl)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(UltraTheme.Motion.gentle) {
                appeared = true
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func register() {
        guard isFormValid else { return }
        
        isLoading = true
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        Task {
            let success = await authVM.register(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            
            await MainActor.run {
                isLoading = false
                
                if !success {
                    let errorGenerator = UINotificationFeedbackGenerator()
                    errorGenerator.notificationOccurred(.error)
                }
            }
        }
    }
}