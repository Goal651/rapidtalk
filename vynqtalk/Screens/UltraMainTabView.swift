//
//  UltraMainTabView.swift
//  vynqtalk
//
//  Ultra-Refined Main Tab View - Perfect Navigation
//  Clean, focused, beautiful
//

import SwiftUI
import Foundation

struct UltraMainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab = 0
    @State private var appeared = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Perfect home tab
            UltraHomeScreen()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    Text("Chats")
                }
                .tag(0)
            
            // Perfect profile tab
            UltraProfileScreen()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "person.crop.circle.fill" : "person.crop.circle")
                    Text("Profile")
                }
                .tag(1)
        }
        .accentColor(UltraTheme.Accent.primary)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(UltraTheme.Motion.gentle) {
                appeared = true
            }
        }
    }
}

// MARK: - Ultra Profile Screen

struct UltraProfileScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Perfect background
            UltraTheme.Backgrounds.gradient
                .ignoresSafeArea()
            
            VStack(spacing: UltraTheme.Layout.xl) {
                // Perfect header
                ultraHeader
                
                // Perfect profile card
                ultraProfileCard
                
                // Perfect actions
                ultraActions
                
                Spacer()
            }
            .padding(.horizontal, UltraTheme.Layout.l)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(UltraTheme.Motion.gentle) {
                appeared = true
            }
        }
    }
    
    // MARK: - Perfect Header
    
    private var ultraHeader: some View {
        HStack {
            Text("Profile")
                .font(UltraTheme.Typography.largeTitle)
                .foregroundColor(UltraTheme.Text.primary)
            
            Spacer()
        }
        .padding(.top, UltraTheme.Layout.m)
    }
    
    // MARK: - Perfect Profile Card
    
    private var ultraProfileCard: some View {
        UltraCard {
            VStack(spacing: UltraTheme.Layout.l) {
                // Perfect avatar
                UltraAvatar(
                    url: nil,
                    size: UltraTheme.Layout.avatarLarge
                )
                
                // Perfect info
                VStack(spacing: UltraTheme.Layout.s) {
                    Text(UserDefaults.standard.string(forKey: "user_name") ?? "User")
                        .font(UltraTheme.Typography.title)
                        .foregroundColor(UltraTheme.Text.primary)
                    
                    Text(UserDefaults.standard.string(forKey: "user_email") ?? "user@example.com")
                        .font(UltraTheme.Typography.caption)
                        .foregroundColor(UltraTheme.Text.tertiary)
                }
            }
        }
    }
    
    // MARK: - Perfect Actions
    
    private var ultraActions: some View {
        VStack(spacing: UltraTheme.Layout.m) {
            // Perfect settings button
            UltraButton(title: "Settings", style: .secondary) {
                // Settings action
            }
            
            // Perfect logout button
            UltraButton(title: "Sign Out") {
                signOut()
            }
        }
    }
    
    private func signOut() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(UltraTheme.Motion.gentle) {
            authVM.logout()
        }
    }
}

// MARK: - Ultra Welcome Screen

struct UltraWelcomeScreen: View {
    @EnvironmentObject var nav: NavigationCoordinator
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Perfect background
            UltraTheme.Backgrounds.gradient
                .ignoresSafeArea()
            
            VStack(spacing: UltraTheme.Layout.xl) {
                Spacer()
                
                // Perfect hero
                VStack(spacing: UltraTheme.Layout.l) {
                    // Perfect icon
                    Circle()
                        .fill(UltraTheme.Accent.primary)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .ultraShadow()
                    
                    // Perfect title
                    VStack(spacing: UltraTheme.Layout.s) {
                        Text("Welcome to VynqTalk")
                            .font(UltraTheme.Typography.largeTitle)
                            .foregroundColor(UltraTheme.Text.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Connect with friends and family through beautiful, secure messaging")
                            .font(UltraTheme.Typography.caption)
                            .foregroundColor(UltraTheme.Text.tertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Perfect actions
                VStack(spacing: UltraTheme.Layout.m) {
                    UltraButton(title: "Get Started") {
                        nav.push(.login)
                    }
                    
                    Button(action: {
                        nav.push(.register)
                    }) {
                        Text("Create Account")
                            .font(UltraTheme.Typography.body)
                            .foregroundColor(UltraTheme.Accent.primary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, UltraTheme.Layout.xl)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            withAnimation(UltraTheme.Motion.gentle.delay(0.2)) {
                appeared = true
            }
        }
    }
}