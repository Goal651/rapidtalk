//
//  Home.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI


enum UserFilterType: String, CaseIterable {
    case all = "All"
    case online = "Online"
    case offline = "Offline"
    case recent = "Recent"
    
    var id: String { rawValue }
}

struct HomeScreen: View {
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    
    @State private var searchText: String = ""
    @State private var selectedFilter: UserFilterType = .all
    @State private var tappedUserId: String? = nil
    
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
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .online:
            users = users.filter { $0.online == true }
        case .offline:
            users = users.filter { $0.online != true }
        case .recent:
            users = users.sorted { (u1, u2) in
                guard let d1 = u1.lastActive, let d2 = u2.lastActive else { return false }
                return d1 > d2
            }
        }
        
        return users
    }
    
    var body: some View {
        GeometryReader { geometry in
            homeContent(geometry: geometry)
        }
        .ignoresSafeArea(edges: .bottom)
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
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                headerSection(spacing: spacing, isLandscape: isLandscape)
                filterSection(spacing: spacing)
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
    private func filterSection(spacing: ResponsiveSpacing) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.s) {
                ForEach(UserFilterType.allCases, id: \.id) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: {
                            withAnimation(AppTheme.AnimationCurves.buttonPress) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, spacing.horizontalPadding)
        }
        .padding(.bottom, AppTheme.Spacing.m)
    }
    
    @ViewBuilder
    private func chatListSection(spacing: ResponsiveSpacing, isLandscape: Bool) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xs) {
                if userVM.isLoading {
                    LoadingView(message: "Loading chats...", style: .spinner)
                        .padding(.top, AppTheme.Spacing.xl)
                } else if let err = userVM.errorMessage {
                    Text(err)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.AccentColors.error)
                        .padding(.top, AppTheme.Spacing.xl)
                } else if filteredUsers.isEmpty {
                    EmptyStateView(filterType: selectedFilter)
                } else {
                    chatListItems(isLandscape: isLandscape)
                }
            }
            .padding(.horizontal, spacing.horizontalPadding)
            .padding(.top, AppTheme.Spacing.xs)
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
        HStack(spacing: AppTheme.Spacing.s) {
            // Avatar with online indicator
            ZStack(alignment: .bottomTrailing) {
                avatar
                
                // Online indicator
                if user.online == true {
                    Circle()
                        .fill(AppTheme.AccentColors.online)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(AppTheme.GradientColors.deepBlack, lineWidth: 2)
                        )
                        .offset(x: 1, y: 1)
                }
            }
            
            // User info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(user.name ?? "Unknown User")
                        .font(isCompact ? AppTheme.Typography.subheadline : AppTheme.Typography.headline)
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
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.TextColors.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Unread badge placeholder
                    // This would be populated from actual message data
                    // UnreadBadge(count: 3)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.s)
        .padding(.vertical, AppTheme.Spacing.s)
        .background(AppTheme.SurfaceColors.surfaceLight)
        .cornerRadius(AppTheme.CornerRadius.m)
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
                        .frame(width: 48, height: 48)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(AppTheme.TextColors.secondary)
                @unknown default:
                    EmptyView()
                }
            }
            .overlay(
                Circle()
                    .stroke(AppTheme.TextColors.tertiary, lineWidth: 1.5)
            )
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(AppTheme.TextColors.secondary)
                .overlay(
                    Circle()
                        .stroke(AppTheme.TextColors.tertiary, lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(isSelected ? AppTheme.TextColors.primary : AppTheme.TextColors.secondary)
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.vertical, AppTheme.Spacing.s)
                .background(
                    isSelected ? AppTheme.AccentColors.primary : AppTheme.SurfaceColors.surfaceLight
                )
                .cornerRadius(AppTheme.CornerRadius.m)
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let filterType: UserFilterType
    @State private var appeared: Bool = false
    
    private var message: String {
        switch filterType {
        case .all:
            return "No conversations yet"
        case .online:
            return "No users online"
        case .offline:
            return "No offline users"
        case .recent:
            return "No recent activity"
        }
    }
    
    private var subtitle: String {
        switch filterType {
        case .all:
            return "Start chatting with someone!"
        default:
            return "Try adjusting your filters"
        }
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "bubble.left.and.bubble.right")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(AppTheme.TextColors.tertiary)
            
            VStack(spacing: AppTheme.Spacing.s) {
                Text(message)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.TextColors.primary)
                
                Text(subtitle)
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
