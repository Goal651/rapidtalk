//
//  AdminUserList.swift
//  vynqtalk
//
//  Admin user management screen
//

import SwiftUI

struct AdminUserList: View {
    @StateObject private var adminVM = AdminViewModel()
    @StateObject private var adminWS = AdminWSManager()
    @State private var searchText = ""
    @State private var selectedFilter: UserFilter = .all
    @State private var selectedSort: UserSort = .lastActive
    @State private var appeared = false
    @State private var selectedUser: AdminUser?
    @State private var showUserDetails = false
    
    enum UserFilter: String, CaseIterable {
        case all = "All"
        case online = "Online"
        case offline = "Offline"
        case suspended = "Suspended"
        
        var apiValue: String {
            switch self {
            case .all: return "all"
            case .online: return "online"
            case .offline: return "offline"
            case .suspended: return "suspended"
            }
        }
    }
    
    enum UserSort: String, CaseIterable {
        case lastActive = "Last Active"
        case messageCount = "Messages"
        case createdAt = "Joined Date"
        
        var apiValue: String {
            switch self {
            case .lastActive: return "lastActive"
            case .messageCount: return "messageCount"
            case .createdAt: return "createdAt"
            }
        }
    }
    
    var filteredUsers: [AdminUser] {
        var users = adminVM.users
        
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
        mainContent
            .navigationTitle("Manage Users")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await adminVM.loadUsers(
                    page: 1,
                    filter: selectedFilter.apiValue,
                    sort: selectedSort.apiValue
                )
                adminWS.connect()
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    appeared = true
                }
            }
            .onDisappear {
                adminWS.disconnect()
            }
            .onChange(of: adminWS.userStatusUpdate) { _, update in
                handleUserStatusUpdate(update)
            }
            .onChange(of: adminWS.messageUpdate) { _, update in
                handleMessageUpdate(update)
            }
            .onChange(of: adminWS.newUser) { _, user in
                handleNewUser(user)
            }
            .onChange(of: adminWS.suspendUpdate) { _, update in
                handleSuspendUpdate(update)
            }
            .onChange(of: selectedFilter) { _, _ in
                Task {
                    await adminVM.loadUsers(
                        page: 1,
                        filter: selectedFilter.apiValue,
                        sort: selectedSort.apiValue
                    )
                }
            }
            .onChange(of: selectedSort) { _, _ in
                Task {
                    await adminVM.loadUsers(
                        page: 1,
                        filter: selectedFilter.apiValue,
                        sort: selectedSort.apiValue
                    )
                }
            }
            .refreshable {
                await adminVM.loadUsers(
                    page: 1,
                    filter: selectedFilter.apiValue,
                    sort: selectedSort.apiValue
                )
            }
            .sheet(isPresented: $showUserDetails) {
                if let user = selectedUser {
                    AdminUserDetails(user: user, adminVM: adminVM)
                }
            }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ZStack {
            AppTheme.GradientColors.deepBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Search and filters
                searchAndFiltersSection
                
                // User list
                userListSection
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleUserStatusUpdate(_ update: AdminUserStatusUpdate?) {
        if let update = update {
            adminVM.handleUserStatusUpdate(update)
        }
    }
    
    private func handleMessageUpdate(_ update: AdminMessageUpdate?) {
        if let update = update {
            adminVM.handleMessageUpdate(update)
        }
    }
    
    private func handleNewUser(_ user: AdminUser?) {
        if let user = user {
            adminVM.handleNewUser(user)
        }
    }
    
    private func handleSuspendUpdate(_ update: AdminSuspendUpdate?) {
        if let update = update {
            adminVM.handleSuspendUpdate(update)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(adminVM.totalUsers) Users")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                Circle()
                    .fill(adminWS.isConnected ? AppTheme.AccentColors.success : .gray)
                    .frame(width: 8, height: 8)
                
                Text(adminWS.isConnected ? "Real-time updates active" : "Connecting...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Search and Filters
    
    private var searchAndFiltersSection: some View {
        VStack(spacing: 16) {
            // Search bar
            ModernSearchBar(text: $searchText)
                .padding(.horizontal, 24)
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(UserFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Sort picker
            HStack {
                Text("Sort by:")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                
                Picker("Sort", selection: $selectedSort) {
                    ForEach(UserSort.allCases, id: \.self) { sort in
                        Text(sort.rawValue).tag(sort)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.AccentColors.primary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - User List
    
    private var userListSection: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if adminVM.isLoading {
                    ProgressView()
                        .tint(AppTheme.AccentColors.primary)
                        .padding(.top, 40)
                } else if let error = adminVM.errorMessage {
                    Text(error)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.AccentColors.error)
                        .padding(.top, 40)
                } else if filteredUsers.isEmpty {
                    Text("No users found")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 40)
                } else {
                    ForEach(filteredUsers) { user in
                        AdminUserRow(user: user) {
                            selectedUser = user
                            showUserDetails = true
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AppTheme.AccentColors.primary : .white.opacity(0.1))
                )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Admin User Row

struct AdminUserRow: View {
    let user: AdminUser
    let action: () -> Void
    @State private var appeared = false
    
    private var avatarURL: URL? {
        guard let avatar = user.avatar else { return nil }
        
        if avatar.lowercased().hasPrefix("http") {
            return URL(string: avatar)
        }
        
        let baseURL = APIClient.environment.baseURL
        let cleanPath = avatar.hasPrefix("/") ? avatar : "/\(avatar)"
        return URL(string: "\(baseURL)\(cleanPath)")
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Avatar with online indicator
                ZStack(alignment: .bottomTrailing) {
                    if let url = avatarURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                            default:
                                defaultAvatar
                            }
                        }
                    } else {
                        defaultAvatar
                    }
                    
                    // Online indicator
                    if user.online {
                        Circle()
                            .fill(AppTheme.AccentColors.success)
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
                        Text(user.name ?? "Unknown")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if user.status == "suspended" {
                            Text("SUSPENDED")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(AppTheme.AccentColors.error)
                                )
                        }
                        
                        Spacer()
                    }
                    
                    Text(user.email ?? "No email")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                    
                    HStack(spacing: 16) {
                        Label("\(user.messageCount)", systemImage: "bubble.left.fill")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        if let lastActive = user.lastActive {
                            Label(formatLastActive(lastActive), systemImage: "clock.fill")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
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
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            )
    }
    
    private func formatLastActive(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}
