//
//  ResponsiveHomeScreen.swift
//  vynqtalk
//
//  Responsive home screen with split view for iPad
//

import SwiftUI

struct ResponsiveHomeScreen: View {
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var messageVM: MessageViewModel
    @EnvironmentObject var wsM: WebSocketManager
    @EnvironmentObject var nav: NavigationCoordinator
    
    @State private var selectedUserId: String?
    @State private var selectedUserName: String?
    @State private var selectedUserAvatar: String?
    @State private var selectedUserLastActive: Date?
    
    var isIPad: Bool {
        return DeviceType.current == .iPad
    }
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = ResponsiveSpacing(screenWidth: geometry.size.width)
            
            if spacing.isTablet {
                // iPad: Split view
                splitView(spacing: spacing)
            } else {
                // iPhone: Regular navigation
                HomeScreen()
            }
        }
    }
    
    // MARK: - Split View (iPad)
    
    private func splitView(spacing: ResponsiveSpacing) -> some View {
        SplitViewContainer(sidebarWidth: spacing.userListWidth) {
            // Sidebar: User List
            userListSidebar
        } detail: {
            // Detail: Chat or Empty State
            if let userId = selectedUserId,
               let userName = selectedUserName {
                ChatScreen(
                    userId: userId,
                    userName: userName,
                    userAvatar: selectedUserAvatar,
                    initialLastActive: selectedUserLastActive,
                    isInSplitView: true  // Tell ChatScreen it's in split view
                )
                .id(userId) // Force refresh when user changes
            } else {
                EmptyChatDetailView()
            }
        }
    }
    
    // MARK: - User List Sidebar
    
    private var userListSidebar: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader
            
            // Search and filters
            searchSection
            
            // User list
            userListSection
        }
    }
    
    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Messages")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
            
            Text("Stay connected with friends")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
    
    private var searchSection: some View {
        VStack(spacing: 20) {
            ModernSearchBar(text: .constant(""))
                .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
    }
    
    private var userListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if userVM.isLoading {
                    ModernLoadingView()
                        .padding(.top, 40)
                } else if let err = userVM.errorMessage {
                    ModernErrorView(message: err)
                        .padding(.top, 40)
                } else if userVM.users.isEmpty {
                    ModernEmptyStateView()
                        .padding(.top, 40)
                } else {
                    ForEach(userVM.users) { user in
                        SplitViewUserRow(
                            user: user,
                            isSelected: selectedUserId == user.id
                        ) {
                            handleUserSelection(user: user)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
        .task {
            await userVM.loadUsers()
        }
        .refreshable {
            await userVM.loadUsers()
        }
    }
    
    // MARK: - Helper
    
    private func handleUserSelection(user: User) {
        guard let id = user.id else { return }
        
        selectedUserId = id
        selectedUserName = user.name ?? "Chat"
        selectedUserAvatar = user.avatar
        selectedUserLastActive = user.lastActive
        
        // Load conversation
        Task {
            await messageVM.loadConversation(meId: authVM.userId, otherUserId: id)
        }
    }
}

// MARK: - Split View User Row

struct SplitViewUserRow: View {
    @EnvironmentObject var wsM: WebSocketManager
    let user: User
    let isSelected: Bool
    let action: () -> Void
    
    private var isOnline: Bool {
        guard let userId = user.id else { return false }
        return wsM.isUserOnline(userId)
    }
    
    private var isTyping: Bool {
        guard let userId = user.id else { return false }
        return wsM.isUserTyping(userId)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Avatar with online indicator
                ZStack(alignment: .bottomTrailing) {
                    avatar
                        .frame(width: 56, height: 56)
                    
                    // Online indicator
                    if isOnline {
                        Circle()
                            .fill(AppTheme.AccentColors.online)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.BackgroundColors.primary, lineWidth: 3)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                
                // User info
                VStack(alignment: .leading, spacing: 6) {
                    Text(user.name ?? "Unknown User")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Show typing indicator if user is typing
                        if isTyping {
                            HStack(spacing: 4) {
                                TypingDotsSmall()
                                Text("typing")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.AccentColors.primary)
                            }
                        }
                        // Show "Active now" if online but not typing
                        else if isOnline {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(AppTheme.AccentColors.online)
                                    .frame(width: 6, height: 6)
                                
                                Text("Active now")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.AccentColors.online)
                            }
                        }
                        // Show bio/email if offline
                        else {
                            Text(user.bio ?? user.email ?? "Start a conversation")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.TextColors.tertiary)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AppTheme.AccentColors.primary.opacity(0.2) : AppTheme.SurfaceColors.base)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? AppTheme.AccentColors.primary : Color.clear,
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var avatar: some View {
        if let avatarURL = user.avatarURL {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 56, height: 56)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                case .failure:
                    defaultAvatar
                @unknown default:
                    defaultAvatar
                }
            }
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 2)
            )
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
