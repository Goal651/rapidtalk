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
    @State private var tappedUserId: Int? = nil
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return userVM.users
        }
        return userVM.users.filter { user in
            let name = user.name?.lowercased() ?? ""
            let email = user.email?.lowercased() ?? ""
            let search = searchText.lowercased()
            return name.contains(search) || email.contains(search)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            homeContent(geometry: geometry)
        }
        .navigationBarBackButtonHidden()
        .task {
            await userVM.loadUsers()
        }
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private func homeContent(geometry: GeometryProxy) -> some View {
        let spacing = ResponsiveSpacing(screenWidth: geometry.size.width)
        let isLandscape = geometry.size.width > geometry.size.height
        
        ZStack {
            AnimatedGradientBackground()
            
            VStack(alignment: .leading, spacing: 0) {
                headerSection(spacing: spacing, isLandscape: isLandscape)
                chatListSection(spacing: spacing, isLandscape: isLandscape)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: spacing.contentMaxWidth)
            .frame(width: geometry.size.width)
        }
    }
    
    @ViewBuilder
    private func headerSection(spacing: ResponsiveSpacing, isLandscape: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Title
            Text("Chats")
                .font(isLandscape ? AppTheme.Typography.title : AppTheme.Typography.largeTitle)
                .foregroundColor(AppTheme.TextColors.primary)
                .padding(.horizontal, spacing.horizontalPadding)
                .padding(.top, isLandscape ? AppTheme.Spacing.m : spacing.topPadding)
            
            // Search Bar
            searchBar(spacing: spacing)
        }
        .padding(.bottom, AppTheme.Spacing.m)
    }
    
    @ViewBuilder
    private func searchBar(spacing: ResponsiveSpacing) -> some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.TextColors.tertiary)
                .font(.system(size: AppTheme.FontSizes.body))
            
            TextField("Search chats...", text: $searchText)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.TextColors.primary)
                .accentColor(AppTheme.AccentColors.primary)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.TextColors.tertiary)
                        .font(.system(size: AppTheme.FontSizes.body))
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, AppTheme.Spacing.m)
        .background(AppTheme.SurfaceColors.surfaceLight)
        .cornerRadius(AppTheme.CornerRadius.m)
        .padding(.horizontal, spacing.horizontalPadding)
    }
    
    @ViewBuilder
    private func chatListSection(spacing: ResponsiveSpacing, isLandscape: Bool) -> some View {
        ScrollView {
            VStack(spacing: isLandscape ? AppTheme.Spacing.s : AppTheme.Spacing.m) {
                if userVM.isLoading {
                    LoadingView(message: "Loading chats...", style: .spinner)
                        .padding(.top, AppTheme.Spacing.xl)
                } else if let err = userVM.errorMessage {
                    Text(err)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.AccentColors.error)
                        .padding(.top, AppTheme.Spacing.xl)
                } else if filteredUsers.isEmpty {
                    EmptyStateView()
                } else {
                    chatListItems(isLandscape: isLandscape)
                }
            }
            .padding(.horizontal, spacing.horizontalPadding)
            .padding(.top, AppTheme.Spacing.s)
            .padding(.bottom, spacing.bottomPadding)
        }
    }
    
    @ViewBuilder
    private func chatListItems(isLandscape: Bool) -> some View {
        ForEach(filteredUsers) { user in
            ChatListItem(user: user, isPressed: tappedUserId == user.id, isCompact: isLandscape)
                .onTapGesture {
                    handleChatTap(user: user)
                }
        }
    }
    
    private func handleChatTap(user: User) {
        guard let id = user.id else { return }
        tappedUserId = id
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            nav.push(.chat(userId: id, name: user.name ?? "Chat"))
            tappedUserId = nil
        }
    }
}

// MARK: - Chat List Item Component

struct ChatListItem: View {
    let user: User
    var isPressed: Bool = false
    var isCompact: Bool = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Avatar with online indicator
            ZStack(alignment: .bottomTrailing) {
                avatar
                
                // Online indicator
                if user.online == true {
                    Circle()
                        .fill(AppTheme.AccentColors.online)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.GradientColors.deepBlack, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            
            // User info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(user.name ?? "Unknown User")
                        .font(isCompact ? AppTheme.Typography.body : AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.TextColors.primary)
                    
                    Spacer()
                    
                    // Timestamp placeholder (would come from last message)
                    Text("Now")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.TextColors.tertiary)
                }
                
                HStack {
                    // Last message preview (using bio as placeholder)
                    Text(user.bio ?? user.email ?? "Start a conversation")
                        .font(isCompact ? AppTheme.Typography.caption : AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.TextColors.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Unread badge placeholder
                    // This would be populated from actual message data
                    // UnreadBadge(count: 3)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, isCompact ? AppTheme.Spacing.s : AppTheme.Spacing.m)
        .background(AppTheme.SurfaceColors.surfaceLight)
        .cornerRadius(AppTheme.CornerRadius.l)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppTheme.AnimationCurves.buttonPress, value: isPressed)
    }
    
    @ViewBuilder
    private var avatar: some View {
        if let avatarString = user.avatar,
           let url = URL(string: avatarString),
           avatarString.lowercased().hasPrefix("http") {
            AsyncImage(url: url) { phase in
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
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .foregroundColor(AppTheme.TextColors.secondary)
                @unknown default:
                    EmptyView()
                }
            }
            .overlay(
                Circle()
                    .stroke(AppTheme.TextColors.tertiary, lineWidth: 2)
            )
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundColor(AppTheme.TextColors.secondary)
                .overlay(
                    Circle()
                        .stroke(AppTheme.TextColors.tertiary, lineWidth: 2)
                )
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    @State private var appeared: Bool = false
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "bubble.left.and.bubble.right")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(AppTheme.TextColors.tertiary)
            
            VStack(spacing: AppTheme.Spacing.s) {
                Text("No conversations yet")
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.TextColors.primary)
                
                Text("Start chatting with someone!")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.TextColors.secondary)
            }
        }
        .padding(.top, AppTheme.Spacing.xxl)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(AppTheme.AnimationCurves.componentAppearance.delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Unread Badge Component

struct UnreadBadge: View {
    let count: Int
    @State private var appeared: Bool = false
    
    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.TextColors.primary)
                .padding(.horizontal, count > 9 ? AppTheme.Spacing.s : AppTheme.Spacing.xs)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(AppTheme.AccentColors.primary)
                .clipShape(Capsule())
                .frame(minWidth: 20, minHeight: 20)
                .scaleEffect(appeared ? 1 : 0)
                .onAppear {
                    withAnimation(AppTheme.AnimationCurves.spring) {
                        appeared = true
                    }
                }
        }
    }
}
