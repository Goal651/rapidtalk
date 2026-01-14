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
    @State private var appeared = false
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
        ZStack {
            // Deep black background like onboarding
            AppTheme.GradientColors.deepBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search and filters
                searchAndFiltersSection
                
                // Chat list
                chatListSection
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            
            // Floating New Chat Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(
                        icon: "plus.message.fill",
                        action: { showNewChatSheet = true }
                    )
                    .padding(.trailing, 24)
                    .padding(.bottom, 100) // Above tab bar
                }
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appeared = true
            }
        }
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Messages")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Stay connected with friends")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Profile button
            Button(action: {}) {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    )
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
    
    // MARK: - Search and Filters Section
    
    @ViewBuilder
    private var searchAndFiltersSection: some View {
        VStack(spacing: 20) {
            // Modern Search Bar
            ModernSearchBar(text: $searchText)
                .padding(.horizontal, 24)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(UserFilterType.allCases, id: \.id) { filter in
                        ModernFilterChip(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter,
                            count: getFilterCount(filter)
                        ) {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 24)
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
                    ModernEmptyStateView(filterType: selectedFilter)
                        .padding(.top, 40)
                } else {
                    ForEach(Array(filteredUsers.enumerated()), id: \.element.id) { index, user in
                        ModernChatListItem(
                            user: user,
                            isPressed: tappedUserId == user.id
                        ) {
                            handleChatTap(user: user)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: appeared)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120) // Space for tab bar and floating button
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFilterCount(_ filter: UserFilterType) -> Int {
        switch filter {
        case .all:
            return userVM.users.count
        case .online:
            return userVM.users.filter { $0.online == true }.count
        case .offline:
            return userVM.users.filter { $0.online != true }.count
        case .recent:
            return userVM.users.filter { $0.lastActive != nil }.count
        }
    }
    
    private func handleChatTap(user: User) {
        guard let id = user.id else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
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
    @State private var appeared = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isFocused ? AppTheme.AccentColors.primary : .white.opacity(0.5))
            
            TextField("Search conversations...", text: $text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .focused($isFocused)
                .submitLabel(.search)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(isFocused ? 0.12 : 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused ? AppTheme.AccentColors.primary.opacity(0.6) : .white.opacity(0.2),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(
            color: isFocused ? AppTheme.AccentColors.primary.opacity(0.2) : .clear,
            radius: isFocused ? 12 : 0,
            y: isFocused ? 4 : 0
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

// MARK: - Modern Filter Chip

struct ModernFilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    @State private var appeared = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? AppTheme.GradientColors.deepBlack : AppTheme.AccentColors.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.9) : AppTheme.AccentColors.primary.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? AppTheme.GradientColors.deepBlack : .white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? .white : .white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
                    )
            )
            .shadow(
                color: isSelected ? .white.opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0,
                y: isSelected ? 4 : 0
            )
        }
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Modern Chat List Item

struct ModernChatListItem: View {
    @EnvironmentObject var wsM: WebSocketManager
    let user: User
    var isPressed: Bool = false
    let action: () -> Void
    @State private var appeared = false
    
    private var isOnline: Bool {
        guard let userId = user.id else { return false }
        return wsM.isUserOnline(userId)
    }
    
    private var lastActiveText: String {
        guard let lastActive = user.lastActive else { return "" }
        
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
                                    .stroke(AppTheme.GradientColors.deepBlack, lineWidth: 3)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                
                // User info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(user.name ?? "Unknown User")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Show last active time if not online
                        if !isOnline && !lastActiveText.isEmpty {
                            Text(lastActiveText)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    HStack {
                        // Show "Active now" if online, otherwise show bio/email
                        if isOnline {
                            HStack(spacing: 6) {
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
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Unread badge (placeholder)
                        if let unreadCount = user.unreadMessages?.count, unreadCount > 0 {
                            Circle()
                                .fill(AppTheme.AccentColors.primary)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(isPressed ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .shadow(
                color: .black.opacity(0.1),
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 50)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
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
                        AppTheme.AccentColors.secondary.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            )
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 2)
            )
    }
}

// MARK: - Supporting Views

struct ModernLoadingView: View {
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.AccentColors.primary))
                .scaleEffect(1.2)
            
            Text("Loading conversations...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
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
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

struct ModernEmptyStateView: View {
    let filterType: UserFilterType
    @State private var appeared = false
    
    private var message: String {
        switch filterType {
        case .all: return "No conversations yet"
        case .online: return "No users online"
        case .offline: return "No offline users"
        case .recent: return "No recent activity"
        }
    }
    
    private var subtitle: String {
        switch filterType {
        case .all: return "Start chatting with someone!"
        default: return "Try adjusting your filters"
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var appeared = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.AccentColors.primary,
                                    AppTheme.AccentColors.secondary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: AppTheme.AccentColors.primary.opacity(0.4),
                    radius: 20,
                    y: 8
                )
        }
        .scaleEffect(isPressed ? 0.9 : (appeared ? 1 : 0))
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
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
}

// MARK: - New Chat Sheet

struct NewChatSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.GradientColors.deepBlack
                    .ignoresSafeArea()
                
                VStack {
                    Text("Start a new conversation")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
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
                    .foregroundColor(.white)
                }
            }
        }
    }
}
