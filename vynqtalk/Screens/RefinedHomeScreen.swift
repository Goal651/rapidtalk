//
//  RefinedHomeScreen.swift
//  vynqtalk
//
//  Refined Premium Home Screen - Calmer, More Premium
//  Reduced visual noise by 20% for better focus
//

import SwiftUI

struct RefinedHomeScreen: View {
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
            // Calmer background - single color instead of gradient
            AppTheme.BackgroundColors.primary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Minimal header
                refinedHeaderSection
                
                // Clean search
                refinedSearchSection
                
                // Simple conversation list
                refinedConversationSection
            }
            
            // Simple floating button
            refinedFloatingButton
        }
        .navigationBarBackButtonHidden()
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
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
    
    // MARK: - Refined Header (Minimal)
    
    @ViewBuilder
    private var refinedHeaderSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Messages")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.primary)
                
                Text("Stay connected")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
            
            Spacer()
            
            // Simple profile button
            Button(action: {
                // Navigate to profile
            }) {
                Circle()
                    .fill(AppTheme.SurfaceColors.base)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppTheme.TextColors.secondary)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
    
    // MARK: - Refined Search (Clean)
    
    @ViewBuilder
    private var refinedSearchSection: some View {
        RefinedSearchBar(text: $searchText)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
    }
    
    // MARK: - Refined Conversation Section (Simple)
    
    @ViewBuilder
    private var refinedConversationSection: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if userVM.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.AccentColors.primary))
                        .padding(.top, 40)
                } else if let err = userVM.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(AppTheme.AccentColors.error)
                        
                        Text("Something went wrong")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.TextColors.primary)
                        
                        Text(err)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(AppTheme.TextColors.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                } else if filteredUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(AppTheme.TextColors.quaternary)
                        
                        VStack(spacing: 4) {
                            Text("No conversations yet")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.TextColors.primary)
                            
                            Text("Start chatting with someone!")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(AppTheme.TextColors.tertiary)
                        }
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(filteredUsers) { user in
                        RefinedConversationItem(
                            user: user,
                            isPressed: tappedUserId == user.id
                        ) {
                            handleChatTap(user: user)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for floating button
        }
    }
    
    // MARK: - Refined Floating Button (Simple)
    
    @ViewBuilder
    private var refinedFloatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    showNewChatSheet = true
                }) {
                    Image(systemName: "plus.message.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(AppTheme.AccentColors.primary)
                        .clipShape(Circle())
                        .shadow(
                            color: AppTheme.AccentColors.primary.opacity(0.3),
                            radius: 12,
                            y: 4
                        )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100) // Above tab bar
            }
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

// MARK: - Refined Search Bar (Clean)

struct RefinedSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
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
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.TextColors.tertiary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.SurfaceColors.base)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isFocused ? AppTheme.AccentColors.primary.opacity(0.5) : Color.clear,
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Refined Conversation Item (Clean)

struct RefinedConversationItem: View {
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
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: lastActive)
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Simple avatar with online indicator
                ZStack(alignment: .bottomTrailing) {
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
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    
                    // Minimal online indicator
                    if isOnline {
                        Circle()
                            .fill(AppTheme.AccentColors.success)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.BackgroundColors.primary, lineWidth: 2)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                
                // Clean user info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.name ?? "Unknown User")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.TextColors.primary)
                        
                        Spacer()
                        
                        if !isOnline && !isTyping && !lastActiveText.isEmpty {
                            Text(lastActiveText)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(AppTheme.TextColors.quaternary)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        if isTyping {
                            HStack(spacing: 4) {
                                RefinedTypingDotsSmall()
                                Text("typing")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(AppTheme.AccentColors.primary)
                            }
                        } else if isOnline {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(AppTheme.AccentColors.success)
                                    .frame(width: 5, height: 5)
                                
                                Text("Active")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(AppTheme.AccentColors.success)
                            }
                        } else {
                            Text(user.bio ?? user.email ?? "Start a conversation")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(AppTheme.TextColors.tertiary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? AppTheme.SurfaceColors.elevated : AppTheme.SurfaceColors.base)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(AppTheme.SurfaceColors.elevated)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppTheme.TextColors.secondary)
            )
    }
}

// MARK: - Refined Typing Dots Small (Minimal)

struct RefinedTypingDotsSmall: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 2) {
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

// MARK: - Refined New Chat Sheet (Clean)

struct RefinedNewChatSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.BackgroundColors.primary
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Start a new conversation")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.primary)
                        .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(20)
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

// MARK: - Refined Loading View

struct RefinedLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.AccentColors.primary))
                .scaleEffect(1.2)
            
            Text("Loading conversations...")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.tertiary)
        }
        .padding(24)
        .background(AppTheme.SurfaceColors.base)
        .cornerRadius(16)
    }
}

// MARK: - Refined Error View

struct RefinedErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(AppTheme.AccentColors.error)
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.primary)
                
                Text(message)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(AppTheme.SurfaceColors.base)
        .cornerRadius(16)
    }
}

// MARK: - Refined Empty State View

struct RefinedEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 56, weight: .medium))
                .foregroundColor(AppTheme.TextColors.quaternary)
            
            VStack(spacing: 8) {
                Text("No conversations yet")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.primary)
                
                Text("Start chatting with someone!")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
        }
        .padding(32)
        .background(AppTheme.SurfaceColors.base)
        .cornerRadius(16)
    }
}