//
//  Home.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    
    @State private var searchText: String = ""
    @State private var tappedUserId: String? = nil
    @State private var showNewChatSheet = false
    
    var filteredUsers: [User] {
        var users = userVM.users
        
        // Apply search
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
            // Clean dark background
            AppTheme.BackgroundColors.primary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search
                searchSection
                
                // Chat list
                chatListSection
            }
            
            // Floating New Chat Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(
                        icon: "plus.message.fill",
                        action: { showNewChatSheet = true }
                    )
                    .padding(.trailing, AppTheme.Layout.screenPadding)
                    .padding(.bottom, 90)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .task {
            await userVM.loadUsers()
        }
        .sheet(isPresented: $showNewChatSheet) {
            NewChatSheet()
        }
        .refreshable {
            await userVM.loadUsers()
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Messages")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.primary)
                
                Text("Stay connected with friends")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
            
            Spacer()
            
            // Profile button
            Button(action: {}) {
                Circle()
                    .fill(AppTheme.SurfaceColors.base)
                    .frame(width: AppTheme.Layout.iconButton, height: AppTheme.Layout.iconButton)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(AppTheme.TextColors.secondary)
                    )
            }
        }
        .padding(.horizontal, AppTheme.Layout.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
    
    // MARK: - Search Section
    
    @ViewBuilder
    private var searchSection: some View {
        ModernSearchBar(text: $searchText)
            .padding(.horizontal, AppTheme.Layout.screenPadding)
            .padding(.bottom, 20)
    }
    
    // MARK: - Chat List Section
    
    @ViewBuilder
    private var chatListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if userVM.isLoading {
                    ModernLoadingView()
                        .padding(.top, 40)
                } else if let err = userVM.errorMessage {
                    ModernErrorView(message: err)
                        .padding(.top, 40)
                } else if filteredUsers.isEmpty {
                    ModernEmptyStateView()
                        .padding(.top, 40)
                } else {
                    ForEach(filteredUsers) { user in
                        ModernChatListItem(
                            user: user,
                            isPressed: tappedUserId == user.id
                        ) {
                            handleChatTap(user: user)
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Layout.screenPadding)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleChatTap(user: User) {
        guard let id = user.id else { return }
        
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

// MARK: - Modern Search Bar

struct ModernSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(isFocused ? AppTheme.AccentColors.primary : AppTheme.TextColors.tertiary)
            
            TextField("Search conversations...", text: $text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
                .focused($isFocused)
                .submitLabel(.search)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.TextColors.tertiary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusMedium)
                .fill(AppTheme.SurfaceColors.base)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusMedium)
                        .stroke(
                            isFocused ? AppTheme.AccentColors.primary.opacity(0.5) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
        .animation(AppTheme.AnimationCurves.spring, value: isFocused)
    }
}

// MARK: - Modern Chat List Item

struct ModernChatListItem: View {
    @EnvironmentObject var wsM: WebSocketManager
    let user: User
    var isPressed: Bool = false
    let action: () -> Void
    
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
            HStack(spacing: 14) {
                // Avatar with online indicator
                ZStack(alignment: .bottomTrailing) {
                    avatar
                        .frame(width: AppTheme.Layout.avatarMedium, height: AppTheme.Layout.avatarMedium)
                    
                    // Online indicator
                    if isOnline {
                        Circle()
                            .fill(AppTheme.AccentColors.online)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.BackgroundColors.primary, lineWidth: 2.5)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                
                // User info
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(user.name ?? "Unknown User")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.TextColors.primary)
                        
                        Spacer()
                        
                        if !isOnline && !isTyping && !lastActiveText.isEmpty {
                            Text(lastActiveText)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.TextColors.quaternary)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        if isTyping {
                            HStack(spacing: 4) {
                                TypingDotsSmall()
                                Text("typing")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.AccentColors.primary)
                            }
                        } else if isOnline {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(AppTheme.AccentColors.online)
                                    .frame(width: 6, height: 6)
                                
                                Text("Active now")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.AccentColors.online)
                            }
                        } else {
                            Text(user.bio ?? user.email ?? "Start a conversation")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.TextColors.tertiary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if let unreadCount = user.unreadMessages?.count, unreadCount > 0 {
                            Circle()
                                .fill(AppTheme.AccentColors.primary)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusMedium)
                    .fill(isPressed ? AppTheme.SurfaceColors.elevated : AppTheme.SurfaceColors.base)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(AppTheme.AnimationCurves.buttonPress, value: isPressed)
    }
    
    @ViewBuilder
    private var avatar: some View {
        if let avatarURL = user.avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: AppTheme.Layout.avatarMedium, height: AppTheme.Layout.avatarMedium)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: AppTheme.Layout.avatarMedium, height: AppTheme.Layout.avatarMedium)
                        .clipShape(Circle())
                case .failure:
                    defaultAvatar
                @unknown default:
                    defaultAvatar
                }
            }
        } else {
            defaultAvatar
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        AppTheme.AccentColors.primary.opacity(0.3),
                        AppTheme.AccentColors.primary.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppTheme.TextColors.secondary)
            )
    }
}

// MARK: - Supporting Views

struct ModernLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.AccentColors.primary))
                .scaleEffect(1.2)
            
            Text("Loading conversations...")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.tertiary)
        }
    }
}

struct ModernErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(AppTheme.AccentColors.error)
            
            Text("Something went wrong")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
            
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.tertiary)
                .multilineTextAlignment(.center)
        }
    }
}

struct ModernEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundColor(AppTheme.TextColors.quaternary)
            
            VStack(spacing: 6) {
                Text("No conversations yet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.primary)
                
                Text("Start chatting with someone!")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(AppTheme.AccentColors.primary)
                )
                .shadow(
                    color: AppTheme.AccentColors.primary.opacity(0.4),
                    radius: isPressed ? 12 : 16,
                    y: isPressed ? 4 : 6
                )
        }
        .scaleEffect(isPressed ? 0.94 : 1.0)
        .animation(AppTheme.AnimationCurves.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - New Chat Sheet

struct NewChatSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.BackgroundColors.primary
                    .ignoresSafeArea()
                
                VStack {
                    Text("Start a new conversation")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.primary)
                        .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.AccentColors.primary)
                }
            }
        }
    }
}


// MARK: - Typing Dots Small (for user list)

struct TypingDotsSmall: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AppTheme.AccentColors.primary)
                    .frame(width: 5, height: 5)
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
        return animationPhase == 1 ? -4 : 0
    }
}
