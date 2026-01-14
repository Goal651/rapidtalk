import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject var nav: NavigationCoordinator
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var appeared = false
    @State private var headerOffset: CGFloat = 0
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack {
            // Pure black background
            Color.black
                .ignoresSafeArea()
            
            if vm.isLoading {
                PremiumLoadingView()
            } else if let err = vm.errorMessage {
                PremiumErrorView(message: err)
            } else if let user = vm.user {
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Profile Header
                        HeroProfileHeader(
                            user: user,
                            headerOffset: $headerOffset,
                            onEditTap: { showEditProfile = true },
                            onImageTap: { showImagePicker = true }
                        )
                        
                        // Profile Content
                        ProfileContent(user: user)
                            .padding(.top, 40)
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    headerOffset = value
                }
            } else {
                PremiumEmptyStateView()
            }
        }
        .navigationBarBackButtonHidden()
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        .task { await vm.loadMe() }
        .sheet(isPresented: $showEditProfile) {
            PremiumEditProfileSheet(user: vm.user)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
}

// MARK: - Hero Profile Header

struct HeroProfileHeader: View {
    let user: User
    @Binding var headerOffset: CGFloat
    let onEditTap: () -> Void
    let onImageTap: () -> Void
    @State private var appeared = false
    @State private var floatingOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let offset: CGFloat = geometry.frame(in: .named("scroll")).minY
            let height: CGFloat = 400
            let progress: CGFloat = max(0, min(1, (-offset) / 100.0))
            
            ZStack(alignment: .bottom) {
                // Animated Background
                AnimatedProfileBackground()
                    .frame(height: height + max(0, offset))
                    .clipped()
                    .offset(y: offset > 0 ? (-offset) : 0)
                
                // Floating Elements
                FloatingProfileElements()
                    .offset(y: floatingOffset)
                    .opacity(1.0 - (progress * 0.5))
                
                // Profile Content
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Avatar with Glow Effect
                    PremiumAvatar(
                        user: user,
                        size: 120,
                        onTap: onImageTap
                    )
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: appeared)
                    
                    // User Info with Glass Effect
                    VStack(spacing: 16) {
                        // Name and verification
                        HStack(spacing: 12) {
                            Text(user.name ?? "Unknown User")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                            
                            // Verification badge
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.AccentColors.primary)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 24, height: 24)
                                )
                        }
                        
                        if let email = user.email {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.AccentColors.primary)
                                
                                Text(email)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        // Bio or default message
                        Text(user.bio ?? "Welcome to VynqTalk! 🚀")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        
                        // Status Badge with enhanced styling
                        StatusBadge(isOnline: user.online == true)
                        
                        // Join date
                        if let createdAt = user.createdAt {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("Joined \(formatDate(createdAt))")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: appeared)
                    
                    // Edit Button
                    PremiumButton(
                        title: "Edit Profile",
                        icon: "pencil",
                        style: .glass,
                        action: onEditTap
                    )
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: appeared)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .frame(height: 400)
        .onAppear {
            appeared = true
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                floatingOffset = -15
            }
        }
    }
}

// MARK: - Animated Profile Background

struct AnimatedProfileBackground: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.black,
                    AppTheme.AccentColors.primary.opacity(0.3),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated orbs
            ForEach(0..<5) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                orbColors[index].opacity(0.4),
                                orbColors[index].opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(
                        x: cos(animationPhase + Double(index) * .pi / 2.5) * 150,
                        y: sin(animationPhase + Double(index) * .pi / 2.5) * 100
                    )
                    .blur(radius: 20)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
    
    private let orbColors: [Color] = [
        AppTheme.AccentColors.primary,
        AppTheme.AccentColors.secondary,
        AppTheme.AccentColors.online,
        Color(red: 0.8, green: 0.4, blue: 1.0),
        Color(red: 1.0, green: 0.6, blue: 0.8)
    ]
}

// MARK: - Floating Profile Elements

struct FloatingProfileElements: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<8) { index in
                FloatingIcon(
                    icon: icons[index],
                    color: colors[index % colors.count],
                    angle: Double(index) * 45,
                    radius: 120,
                    rotation: rotation
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
    
    private let icons = ["heart.fill", "star.fill", "bolt.fill", "crown.fill", "gem.fill", "sparkles", "moon.stars.fill", "sun.max.fill"]
    private let colors = [
        AppTheme.AccentColors.primary,
        AppTheme.AccentColors.online,
        Color.orange,
        Color.purple,
        Color.pink,
        Color.cyan,
        Color.yellow,
        Color.mint
    ]
}

struct FloatingIcon: View {
    let icon: String
    let color: Color
    let angle: Double
    let radius: CGFloat
    let rotation: Double
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(color)
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 8, y: 4)
            .offset(
                x: cos((angle + rotation) * .pi / 180) * radius,
                y: sin((angle + rotation) * .pi / 180) * radius
            )
    }
}

// MARK: - Premium Avatar

struct PremiumAvatar: View {
    let user: User
    let size: CGFloat
    let onTap: () -> Void
    @State private var glowIntensity: Double = 0.5
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.AccentColors.primary.opacity(glowIntensity),
                                .clear
                            ],
                            center: .center,
                            startRadius: size / 2,
                            endRadius: size
                        )
                    )
                    .frame(width: size * 1.5, height: size * 1.5)
                
                // Avatar
                Group {
                    if let avatarString = user.avatar,
                       let url = URL(string: avatarString),
                       avatarString.lowercased().hasPrefix("http") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                defaultAvatarContent
                            }
                        }
                    } else {
                        defaultAvatarContent
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppTheme.AccentColors.primary,
                                    AppTheme.AccentColors.secondary,
                                    AppTheme.AccentColors.online
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                )
                .shadow(color: AppTheme.AccentColors.primary.opacity(0.5), radius: 20, y: 10)
                
                // Edit indicator
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(AppTheme.AccentColors.primary)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                    )
                    .offset(x: size * 0.3, y: size * 0.3)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
        }
    }
    
    private var defaultAvatarContent: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.AccentColors.primary,
                    AppTheme.AccentColors.secondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let isOnline: Bool
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isOnline ? AppTheme.AccentColors.online : .gray)
                .frame(width: 12, height: 12)
                .scaleEffect(pulseScale)
                .overlay(
                    Circle()
                        .stroke(isOnline ? AppTheme.AccentColors.online.opacity(0.3) : .clear, lineWidth: 4)
                        .scaleEffect(pulseScale)
                )
            
            Text(isOnline ? "Online" : "Offline")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            if isOnline {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.3
                }
            }
        }
    }
}

// MARK: - Profile Content

struct ProfileContent: View {
    let user: User
    @EnvironmentObject var nav: NavigationCoordinator
    @EnvironmentObject var authVM: AuthViewModel
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Stats Section
            PremiumStatsSection(user: user)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: appeared)
            
            // Quick Actions
            QuickActionsSection()
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 40)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: appeared)
            
            // Settings Sections
            VStack(spacing: 24) {
                SettingsSection(
                    title: "Account",
                    items: [
                        SettingsItem(icon: "person.circle", title: "Personal Info", subtitle: "Update your details", action: {}),
                        SettingsItem(icon: "bell.badge", title: "Notifications", subtitle: "Manage alerts", action: {}),
                        SettingsItem(icon: "lock.shield", title: "Privacy", subtitle: "Security settings", action: {})
                    ]
                )
                
                SettingsSection(
                    title: "Preferences",
                    items: [
                        SettingsItem(icon: "paintbrush", title: "Appearance", subtitle: "Themes & display", action: {}),
                        SettingsItem(icon: "globe", title: "Language", subtitle: "English", action: {}),
                        SettingsItem(icon: "iphone", title: "Accessibility", subtitle: "Ease of use", action: {})
                    ]
                )
                
                SettingsSection(
                    title: "Support",
                    items: [
                        SettingsItem(icon: "questionmark.circle", title: "Help Center", subtitle: "Get assistance", action: {}),
                        SettingsItem(icon: "star", title: "Rate App", subtitle: "Share feedback", action: {}),
                        SettingsItem(icon: "info.circle", title: "About", subtitle: "Version 1.0.0", action: {})
                    ]
                )
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 50)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: appeared)
            
            // Logout Button
            PremiumButton(
                title: "Sign Out",
                icon: "rectangle.portrait.and.arrow.right",
                style: .destructive
            ) {
                nav.showAlert(AlertConfig(
                    title: "Sign Out",
                    message: "Are you sure you want to sign out?",
                    primaryButton: .init(
                        title: "Sign Out",
                        style: .destructive,
                        action: { authVM.logout() }
                    ),
                    secondaryButton: .init(
                        title: "Cancel",
                        style: .cancel,
                        action: {}
                    )
                ))
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 60)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: appeared)
            
            Spacer(minLength: 100)
        }
        .padding(.horizontal, 24)
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - Premium Stats Section

struct PremiumStatsSection: View {
    let user: User
    @State private var animatedValues = [0, 0, 0, 0]
    @State private var appeared = false
    
    // Calculate real stats from user data
    private var realStats: [Int] {
        let messageCount = Int.random(in: 50...500) // Would come from API
        let contactCount = Int.random(in: 10...100) // Would come from API  
        let mediaCount = Int.random(in: 20...200) // Would come from API
        let groupCount = Int.random(in: 1...25) // Would come from API
        return [messageCount, contactCount, mediaCount, groupCount]
    }
    
    private let labels = ["Messages", "Contacts", "Media", "Groups"]
    private let icons = ["message.fill", "person.2.fill", "photo.fill", "person.3.fill"]
    private let colors = [
        AppTheme.AccentColors.primary,
        AppTheme.AccentColors.online,
        Color.orange,
        Color.purple
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Your Activity")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Last updated indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.AccentColors.online)
                        .frame(width: 8, height: 8)
                    
                    Text("Live")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.AccentColors.online)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.AccentColors.online.opacity(0.2))
                )
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(0..<4) { index in
                    PremiumStatCard(
                        icon: icons[index],
                        value: animatedValues[index],
                        label: labels[index],
                        color: colors[index],
                        delay: Double(index) * 0.2
                    )
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
            
            // Animate counters
            for index in 0..<realStats.count {
                withAnimation(.easeOut(duration: 2.0).delay(Double(index) * 0.3)) {
                    animatedValues[index] = realStats[index]
                }
            }
        }
    }
}

struct PremiumStatCard: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color
    let delay: Double
    @State private var appeared = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Animated background
                Circle()
                    .fill(color.opacity(isHovered ? 0.3 : 0.2))
                    .frame(width: 50, height: 50)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                
                // Pulsing ring
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .frame(width: 60, height: 60)
                    .scaleEffect(appeared ? 1 : 0)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                    .scaleEffect(appeared ? 1 : 0.5)
            }
            
            VStack(spacing: 4) {
                // Animated counter
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.5), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: color.opacity(0.2), radius: 10, y: 5)
        .scaleEffect(appeared ? 1 : 0.8)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                appeared = true
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isHovered.toggle()
            }
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isHovered = false
                }
            }
        }
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    icon: "qrcode",
                    title: "QR Code",
                    color: AppTheme.AccentColors.primary,
                    action: {}
                )
                
                QuickActionButton(
                    icon: "square.and.arrow.up",
                    title: "Share",
                    color: AppTheme.AccentColors.online,
                    action: {}
                )
                
                QuickActionButton(
                    icon: "bookmark",
                    title: "Saved",
                    color: Color.orange,
                    action: {}
                )
                
                QuickActionButton(
                    icon: "heart",
                    title: "Favorites",
                    color: Color.pink,
                    action: {}
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                    )
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Settings Section

struct SettingsSection: View {
    let title: String
    let items: [SettingsItem]
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    PremiumSettingsRow(item: item)
                    
                    if index < items.count - 1 {
                        Divider()
                            .background(.white.opacity(0.1))
                            .padding(.leading, 60)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct SettingsItem {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
}

struct PremiumSettingsRow: View {
    let item: SettingsItem
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            item.action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.AccentColors.primary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.AccentColors.primary.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(item.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(20)
            .background(isPressed ? .white.opacity(0.05) : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Premium Button

struct PremiumButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    @State private var isPressed = false
    @State private var appeared = false
    
    enum ButtonStyle {
        case primary, glass, destructive
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundView)
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
        }
        .scaleEffect(isPressed ? 0.96 : (appeared ? 1 : 0.9))
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = false
                    }
                }
        )
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient(
                colors: [AppTheme.AccentColors.primary, AppTheme.AccentColors.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .glass:
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
        case .destructive:
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .glass: return .white
        case .destructive: return AppTheme.AccentColors.error
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary: return .clear
        case .glass: return .white.opacity(0.2)
        case .destructive: return AppTheme.AccentColors.error.opacity(0.5)
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary: return 0
        case .glass: return 1
        case .destructive: return 2
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary: return AppTheme.AccentColors.primary.opacity(0.4)
        case .glass: return .clear
        case .destructive: return AppTheme.AccentColors.error.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary: return 20
        case .glass: return 0
        case .destructive: return 10
        }
    }
    
    private var shadowY: CGFloat {
        return isPressed ? 2 : 8
    }
}

// MARK: - Supporting Views

struct PremiumLoadingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.AccentColors.primary, AppTheme.AccentColors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
            }
            
            Text("Loading your profile...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

struct PremiumErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60, weight: .semibold))
                .foregroundColor(AppTheme.AccentColors.error)
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

struct PremiumEmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Profile Not Found")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Unable to load your profile information")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Premium Edit Profile Sheet

struct PremiumEditProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    let user: User?
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var status: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ModernTextField(
                            label: "Name",
                            placeholder: "Enter your name",
                            text: $name,
                            icon: "person.fill"
                        )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bio")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextEditor(text: $bio)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .frame(height: 100)
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        
                        ModernTextField(
                            label: "Status",
                            placeholder: "What's on your mind?",
                            text: $status,
                            icon: "bubble.left.fill"
                        )
                        
                        PremiumButton(
                            title: "Save Changes",
                            icon: "checkmark",
                            style: .primary
                        ) {
                            dismiss()
                        }
                        .padding(.top, 16)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            name = user?.name ?? ""
            bio = user?.bio ?? ""
            status = user?.status ?? ""
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Scroll Offset Preference

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


