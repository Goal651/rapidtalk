//
//  Home.swift
//  vynqtalk
//
//  Premium Home Screen - Apple Quality Design
//  Updated to use new premium components
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    @EnvironmentObject var wsM: WebSocketManager
    
    @State private var searchText: String = ""
    @State private var tappedUserId: String? = nil
    @State private var showNewChatSheet = false
    @State private var appeared = false
    
    var filteredUsers: [User] {
        var users = userVM.users
        
        if !searchText.isEmpty {
            users = users.filter { user in
                let name = user.name?.lowercased() ?? ""
                let email = user.email?.lowercased() ?? ""
                let search = searchText.lowercased()
                return name.contains(search) || email.contains(search)
            }
        }
        
        return users
    }
    
    var body: some View {
        ZStack {
            // Premium gradient background
            AppTheme.BackgroundColors.primaryGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Hero header section
                heroHeaderSection
                
                // Search section
                searchSection
                
                // Conversation cards
                conversationCardsSection
            }
            
            // Floating new chat button
            floatingNewChatButton
        }
        .navigationBarBackButtonHidden()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(AppTheme.Animations.cardAppear) {
                appeared = true
            }
        }
        .task {
            await userVM.loadUsers()
        }
        .sheet(isPresented: $showNewChatSheet) {
            RefinedNewChatSheet()
        }
        .refreshable {
            await userVM.loadUsers()
        }
    }
    
    // MARK: - Hero Header Section
    
    @ViewBuilder
    private var heroHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacing16) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Layout.spacing8) {
                    Text("Messages")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.TextColors.primary)
                    
                    Text("Stay connected with your world")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.TextColors.tertiary)
                }
                
                Spacer()
                
                // Profile avatar button
                profileAvatarButton
            }
            
            // Quick stats with glass cards
            quickStatsSection
        }
        .padding(.horizontal, AppTheme.Layout.screenPadding)
        .padding(.top, AppTheme.Layout.spacing16)
        .padding(.bottom, AppTheme.Layout.spacing24)
    }
    
    private var profileAvatarButton: some View {
        PremiumIconButton(
            icon: "person.crop.circle.fill",
            style: .secondary,
            size: .medium
        ) {
            // Navigate to profile
        }
    }
    
    private var quickStatsSection: some View {
        HStack(spacing: AppTheme.Layout.spacing12) {
            // Active conversations
            QuickStatCard(
                icon: "bubble.left.and.bubble.right.fill",
                title: "\(filteredUsers.count)",
                subtitle: "Conversations",
                color: AppTheme.AccentColors.primary
            )
            
            // Online friends
            QuickStatCard(
                icon: "person.2.fill",
                title: "\(onlineUsersCount)",
                subtitle: "Online",
                color: AppTheme.AccentColors.success
            )
            
            Spacer()
        }
    }
    
    private var onlineUsersCount: Int {
        filteredUsers.filter { user in
            guard let userId = user.id else { return false }
            return wsM.isUserOnline(userId)
        }.count
    }
    
    // MARK: - Search Section
    
    @ViewBuilder
    private var searchSection: some View {
        RefinedSearchBar(text: $searchText)
            .padding(.horizontal, AppTheme.Layout.screenPadding)
            .padding(.bottom, AppTheme.Layout.spacing20)
    }
    
    // MARK: - Conversation Cards Section
    
    @ViewBuilder
    private var conversationCardsSection: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Layout.spacing16) {
                if userVM.isLoading {
                    RefinedLoadingView()
                        .padding(.top, AppTheme.Layout.spacing48)
                } else if let err = userVM.errorMessage {
                    RefinedErrorView(message: err)
                        .padding(.top, AppTheme.Layout.spacing48)
                } else if filteredUsers.isEmpty {
                    RefinedEmptyStateView()
                        .padding(.top, AppTheme.Layout.spacing48)
                } else {
                    ForEach(Array(filteredUsers.enumerated()), id: \.element.id) { index, user in
                        RefinedConversationItem(
                            user: user,
                            isPressed: tappedUserId == user.id
                        ) {
                            handleChatTap(user: user)
                        }
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            )
                        )
                        .animation(
                            AppTheme.Animations.cardAppear.delay(Double(index) * 0.05),
                            value: appeared
                        )
                    }
                }
            }
            .padding(.horizontal, AppTheme.Layout.screenPadding)
            .padding(.bottom, 120) // Space for floating button
        }
    }
    
    // MARK: - Floating New Chat Button
    
    @ViewBuilder
    private var floatingNewChatButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                PremiumFloatingActionButton(
                    icon: "plus.message.fill",
                    size: .standard
                ) {
                    showNewChatSheet = true
                }
                .padding(.trailing, AppTheme.Layout.screenPadding)
                .padding(.bottom, 100) // Above tab bar
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleChatTap(user: User) {
        guard let id = user.id else { return }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        tappedUserId = id
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            nav.push(.chat(
                userId: id,
                name: user.name ?? "Chat",
                avatar: user.avatar,
                lastActive: user.lastActive
            ))
            tappedUserId = nil
        }
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Layout.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.TextColors.primary)
                
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
        }
        .padding(AppTheme.Layout.spacing16)
        .ultraThinGlass()
        .glassShadow()
    }
}

// MARK: - Premium Conversation Card

struct PremiumConversationCard: View {
    @EnvironmentObject var wsM: WebSocketManager
    let user: User
    var isPressed: Bool = false
    let action: () -> Void
    
    @State private var appeared = false
    
    private var isOnline: Bool {
        guard let userId = user.id else { return false }
        return wsM.isUserOnline(userId)
    }
    
    private var isTyping: Bool {
        guard let userId = user.id else { return false }
        return wsM.isUserTyping(userId)
    }
    
    private var lastActiveText: String {
        if let userId = user.id,
           let cachedLastActive = wsM.getLastActive(for: userId) {
            return formatLastActive(cachedLastActive)
        }
        
        guard let lastActive = user.lastActive else { return "" }
        return formatLastActive(lastActive)
    }
    
    private func formatLastActive(_ lastActive: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(lastActive)
        
        if interval < 60 {
            return "Active now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: lastActive)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Layout.spacing20) {
                // Large avatar with online indicator
                avatarSection
                
                // User info section
                userInfoSection
                
                Spacer()
                
                // Status and chevron
                trailingSection
            }
            .padding(AppTheme.Layout.spacing20)
            .premiumGlassCard()
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .glassShadow()
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(AppTheme.Animations.cardAppear) {
                appeared = true
            }
        }
        .animation(AppTheme.Animations.buttonPress, value: isPressed)
    }
    
    private var avatarSection: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar
            Group {
                if let avatarURL = user.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            defaultAvatar
                        }
                    }
                } else {
                    defaultAvatar
                }
            }
            .frame(width: AppTheme.Layout.avatarLarge, height: AppTheme.Layout.avatarLarge)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            
            // Online indicator
            if isOnline {
                Circle()
                    .fill(AppTheme.AccentColors.success)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.BackgroundColors.primary, lineWidth: 3)
                    )
                    .offset(x: 4, y: 4)
                    .scaleEffect(isOnline ? 1 : 0)
                    .animation(AppTheme.Animations.springBouncy, value: isOnline)
            }
        }
    }
    
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Layout.spacing8) {
            // Name
            Text(user.name ?? "Unknown User")
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.TextColors.primary)
                .lineLimit(1)
            
            // Status or last message
            HStack(spacing: AppTheme.Layout.spacing8) {
                if isTyping {
                    HStack(spacing: AppTheme.Layout.spacing4) {
                        PremiumTypingDots()
                        Text("typing")
                            .font(AppTheme.Typography.footnote)
                            .foregroundColor(AppTheme.AccentColors.primary)
                    }
                } else if isOnline {
                    HStack(spacing: AppTheme.Layout.spacing8) {
                        Circle()
                            .fill(AppTheme.AccentColors.success)
                            .frame(width: 6, height: 6)
                        
                        Text("Active now")
                            .font(AppTheme.Typography.footnote)
                            .foregroundColor(AppTheme.AccentColors.success)
                    }
                } else {
                    Text(user.bio ?? user.email ?? "Start a conversation")
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.TextColors.tertiary)
                        .lineLimit(2)
                }
            }
        }
    }
    
    private var trailingSection: some View {
        VStack(alignment: .trailing, spacing: AppTheme.Layout.spacing8) {
            // Time or unread indicator
            if !isOnline && !isTyping && !lastActiveText.isEmpty {
                Text(lastActiveText)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.TextColors.quaternary)
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.TextColors.quaternary)
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(AppTheme.GlassMaterials.premium)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(AppTheme.TextColors.secondary)
            )
    }
}

// MARK: - Premium Typing Dots

struct PremiumTypingDots: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AppTheme.AccentColors.primary)
                    .frame(width: 4, height: 4)
                    .offset(y: dotOffset(for: index))
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            animationPhase = 1
        }
    }
    
    private func dotOffset(for index: Int) -> CGFloat {
        return animationPhase == 1 ? -3 : 0
    }
}

// MARK: - Premium New Chat Sheet

struct PremiumNewChatSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.BackgroundColors.primaryGradient
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.Layout.spacing24) {
                    Text("Start a new conversation")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.TextColors.primary)
                        .padding(.top, AppTheme.Layout.spacing24)
                    
                    Spacer()
                }
                .padding(AppTheme.Layout.screenPadding)
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.AccentColors.primary)
                    .font(AppTheme.Typography.bodyMedium)
                }
            }
        }
    }
}
