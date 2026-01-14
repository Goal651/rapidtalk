//
//  OnboardingScreen.swift
//  vynqtalk
//
//  Created by wigothehacker on 01/14/26.
//

import SwiftUI

struct OnboardingScreen: View {
    @EnvironmentObject var nav: NavigationCoordinator
    @State private var currentPage = 0
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Deep black background
            AppTheme.GradientColors.deepBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: {
                        nav.push(.register)
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                
                // Paged content
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        title: "Instant messaging\nmade simple",
                        subtitle: "Send messages, photos, and videos\nto anyone, anywhere in real-time",
                        illustration: .messaging,
                        pageIndex: 0
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        title: "Stay connected\nwith friends",
                        subtitle: "See who's online and start\nconversations instantly",
                        illustration: .connected,
                        pageIndex: 1
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        title: "Secure and\nprivate chats",
                        subtitle: "Your conversations are encrypted\nand protected end-to-end",
                        illustration: .secure,
                        pageIndex: 2
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(currentPage == index ? AppTheme.AccentColors.primary : .white.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // Action buttons
                VStack(spacing: 16) {
                    if currentPage == 2 {
                        // Last page - show Get Started
                        Button(action: {
                            nav.push(.register)
                        }) {
                            Text("Get Started")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(AppTheme.GradientColors.deepBlack)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(.white)
                                .cornerRadius(28)
                        }
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .scale))
                        
                        Button(action: {
                            nav.push(.login)
                        }) {
                            Text("Sign In")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(.white.opacity(0.3), lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        // Other pages - show Continue
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(AppTheme.GradientColors.deepBlack)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(.white)
                                .cornerRadius(28)
                        }
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - Onboarding Page

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let illustration: IllustrationType
    let pageIndex: Int
    
    @State private var illustrationAppeared = false
    @State private var textAppeared = false
    @State private var floatingOffset: CGFloat = 0
    
    enum IllustrationType {
        case messaging
        case connected
        case secure
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            // 3D Illustration
            illustrationView
                .frame(height: 320)
                .opacity(illustrationAppeared ? 1 : 0)
                .scaleEffect(illustrationAppeared ? 1 : 0.8)
                .offset(y: illustrationAppeared ? 0 : 30)
            
            Spacer()
                .frame(height: 60)
            
            // Title
            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(textAppeared ? 1 : 0)
                .offset(y: textAppeared ? 0 : 20)
            
            Spacer()
                .frame(height: 16)
            
            // Subtitle
            Text(subtitle)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(textAppeared ? 1 : 0)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                illustrationAppeared = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                textAppeared = true
            }
            
            // Floating animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatingOffset = -10
            }
        }
    }
    
    @ViewBuilder
    private var illustrationView: some View {
        switch illustration {
        case .messaging:
            messagingIllustration
        case .connected:
            connectedIllustration
        case .secure:
            secureIllustration
        }
    }
    
    // MARK: - Illustration 1: Messaging
    
    @ViewBuilder
    private var messagingIllustration: some View {
        ZStack {
            // Base platforms
            platformStack
            
            // Floating message bubbles
            VStack(spacing: 20) {
                chatBubbleCard(
                    color: AppTheme.AccentColors.primary,
                    icon: "message.fill",
                    rotation: -12,
                    offset: CGSize(width: -40, height: -70),
                    scale: 1.0
                )
                .offset(y: floatingOffset * 1.2)
                
                chatBubbleCard(
                    color: AppTheme.AccentColors.online,
                    icon: "paperplane.fill",
                    rotation: 8,
                    offset: CGSize(width: 50, height: -20),
                    scale: 0.9
                )
                .offset(y: floatingOffset * 0.9)
                
                chatBubbleCard(
                    color: Color(hex: "FB923C"),
                    icon: "photo.fill",
                    rotation: -5,
                    offset: CGSize(width: -30, height: 30),
                    scale: 0.85
                )
                .offset(y: floatingOffset * 1.1)
            }
            .offset(y: -20)
        }
    }
    
    // MARK: - Illustration 2: Connected
    
    @ViewBuilder
    private var connectedIllustration: some View {
        ZStack {
            // Base platforms
            platformStack
            
            // User avatars with online indicators
            VStack(spacing: 25) {
                userAvatarCard(
                    color: AppTheme.AccentColors.primary,
                    icon: "person.fill",
                    isOnline: true,
                    rotation: -10,
                    offset: CGSize(width: -45, height: -60)
                )
                .offset(y: floatingOffset * 1.1)
                
                userAvatarCard(
                    color: Color(hex: "EC4899"),
                    icon: "person.fill",
                    isOnline: true,
                    rotation: 12,
                    offset: CGSize(width: 45, height: -10)
                )
                .offset(y: floatingOffset * 0.95)
                
                userAvatarCard(
                    color: AppTheme.AccentColors.online,
                    icon: "person.fill",
                    isOnline: true,
                    rotation: -6,
                    offset: CGSize(width: -20, height: 40)
                )
                .offset(y: floatingOffset * 1.05)
            }
            .offset(y: -20)
        }
    }
    
    // MARK: - Illustration 3: Secure
    
    @ViewBuilder
    private var secureIllustration: some View {
        ZStack {
            // Base platforms
            platformStack
            
            // Security elements
            VStack(spacing: 20) {
                chatBubbleCard(
                    color: AppTheme.AccentColors.online,
                    icon: "lock.shield.fill",
                    rotation: -8,
                    offset: CGSize(width: -35, height: -70),
                    scale: 1.1
                )
                .offset(y: floatingOffset * 1.15)
                
                chatBubbleCard(
                    color: AppTheme.AccentColors.primary,
                    icon: "checkmark.seal.fill",
                    rotation: 10,
                    offset: CGSize(width: 40, height: -15),
                    scale: 0.95
                )
                .offset(y: floatingOffset * 0.9)
                
                chatBubbleCard(
                    color: Color(hex: "8B5CF6"),
                    icon: "key.fill",
                    rotation: -12,
                    offset: CGSize(width: -25, height: 35),
                    scale: 0.85
                )
                .offset(y: floatingOffset * 1.08)
            }
            .offset(y: -20)
        }
    }
    
    // MARK: - Reusable Components
    
    @ViewBuilder
    private var platformStack: some View {
        VStack(spacing: -20) {
            // Bottom platform (largest) - Blue
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.AccentColors.primary.opacity(0.4),
                            AppTheme.AccentColors.primary.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 200, height: 45)
                .shadow(color: AppTheme.AccentColors.primary.opacity(0.3), radius: 15, y: 8)
                .offset(y: floatingOffset * 0.5)
            
            // Middle platform - Darker blue
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.AccentColors.primary.opacity(0.3),
                            AppTheme.AccentColors.primary.opacity(0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 160, height: 38)
                .shadow(color: AppTheme.AccentColors.primary.opacity(0.2), radius: 12, y: 6)
                .offset(y: floatingOffset * 0.7)
            
            // Top platform (smallest) - Lightest
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.AccentColors.primary.opacity(0.25),
                            AppTheme.AccentColors.primary.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 32)
                .shadow(color: AppTheme.AccentColors.primary.opacity(0.15), radius: 10, y: 5)
                .offset(y: floatingOffset)
        }
        .offset(y: 50)
    }
    
    @ViewBuilder
    private func chatBubbleCard(color: Color, icon: String, rotation: Double, offset: CGSize, scale: CGFloat = 1.0) -> some View {
        ZStack {
            // Card shadow
            RoundedRectangle(cornerRadius: 18)
                .fill(color.opacity(0.3))
                .frame(width: 75 * scale, height: 55 * scale)
                .blur(radius: 10)
                .offset(x: offset.width, y: offset.height + 6)
            
            // Card
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 75 * scale, height: 55 * scale)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 26 * scale, weight: .semibold))
                        .foregroundColor(.white)
                )
                .shadow(color: color.opacity(0.4), radius: 12, y: 6)
                .rotation3DEffect(
                    .degrees(rotation),
                    axis: (x: 0, y: 1, z: 0)
                )
                .offset(x: offset.width, y: offset.height)
        }
    }
    
    @ViewBuilder
    private func userAvatarCard(color: Color, icon: String, isOnline: Bool, rotation: Double, offset: CGSize) -> some View {
        ZStack {
            // Card shadow
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 70, height: 70)
                .blur(radius: 10)
                .offset(x: offset.width, y: offset.height + 6)
            
            // Avatar circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                )
                .overlay(
                    // Online indicator
                    Circle()
                        .fill(AppTheme.AccentColors.online)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.GradientColors.deepBlack, lineWidth: 3)
                        )
                        .offset(x: 24, y: 24)
                        .opacity(isOnline ? 1 : 0)
                )
                .shadow(color: color.opacity(0.4), radius: 12, y: 6)
                .rotation3DEffect(
                    .degrees(rotation),
                    axis: (x: 0, y: 1, z: 0)
                )
                .offset(x: offset.width, y: offset.height)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
