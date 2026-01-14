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
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    // Title
                    Text("Chats")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(AppTheme.TextColors.primary)
                        .padding(.horizontal, AppTheme.Spacing.l)
                        .padding(.top, AppTheme.Spacing.xl)
                    
                    // Search Bar
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
                    .padding(.horizontal, AppTheme.Spacing.l)
                }
                .padding(.bottom, AppTheme.Spacing.m)
                
                // User/Chat list
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.m) {
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
                            ForEach(filteredUsers) { user in
                                ChatListItem(user: user, isPressed: tappedUserId == user.id)
                                    .onTapGesture {
                                        guard let id = user.id else { return }
                                        // Trigger tap animation
                                        tappedUserId = id
                                        
                                        // Navigate after brief delay for animation
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            nav.push(.chat(userId: id, name: user.name ?? "Chat"))
                                            tappedUserId = nil
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.l)
                    .padding(.top, AppTheme.Spacing.s)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
                
                Spacer(minLength: 0)
            }
        }
        .navigationBarBackButtonHidden()
        .task {
            await userVM.loadUsers()
        }
    }
}

// MARK: - Chat List Item Component

struct ChatListItem: View {
    let user: User
    var isPressed: Bool = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // Avatar with online indicator
            ZStack(alignment: .bottomTrailing) {
                avatar
                
                // Online indicator
                if user.online == true {
                    Circle()
                        .fill(AppTheme.AccentColors.success)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.GradientColors.deepNavyBlack, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            
            // User info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(user.name ?? "Unknown User")
                        .font(AppTheme.Typography.headline)
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
                        .font(AppTheme.Typography.subheadline)
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
        .padding(.vertical, AppTheme.Spacing.m)
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
        }
    }
}
