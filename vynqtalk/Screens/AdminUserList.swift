//
//  AdminUserList.swift
//  vynqtalk
//
//  Professional admin user management with glassmorphism table design
//

import SwiftUI

struct AdminUserList: View {
    @StateObject private var adminVM = AdminViewModel()
    @StateObject private var adminWS = AdminWSManager()
    @State private var searchText = ""
    @State private var selectedFilter: UserFilter = .all
    @State private var selectedSort: UserSort = .lastActive
    @State private var selectedUser: AdminUser?
    @State private var showUserDetails = false
    @State private var currentPage = 1
    
    enum UserFilter: String, CaseIterable {
        case all = "All Users"
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
        
        var color: Color {
            switch self {
            case .all: return AppTheme.TextColors.secondary
            case .online: return AppTheme.AccentColors.success
            case .offline: return AppTheme.TextColors.tertiary
            case .suspended: return AppTheme.AccentColors.error
            }
        }
    }
    
    enum UserSort: String, CaseIterable {
        case lastActive = "Last Active"
        case messageCount = "Messages"
        case createdAt = "Joined Date"
        case name = "Name"
        
        var apiValue: String {
            switch self {
            case .lastActive: return "lastActive"
            case .messageCount: return "messageCount"
            case .createdAt: return "createdAt"
            case .name: return "name"
            }
        }
    }
    
    var filteredUsers: [AdminUser] {
        var users = adminVM.users
        
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
            // Black background like other screens
            AppTheme.BackgroundColors.primary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header section
                headerSection
                
                // Main content
                mainContent
            }
        }
        .navigationTitle("User Management")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadUsers()
            adminWS.connect()
        }
        .onDisappear {
            adminWS.disconnect()
        }
        .onChange(of: selectedFilter) { _, _ in
            Task { await loadUsers() }
        }
        .onChange(of: selectedSort) { _, _ in
            Task { await loadUsers() }
        }
        .refreshable {
            await loadUsers()
        }
        .sheet(isPresented: $showUserDetails) {
            if let user = selectedUser {
                UserDetailPanel(user: user, adminVM: adminVM)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Title and stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("User Management")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.primary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(adminWS.isConnected ? AppTheme.AccentColors.success : AppTheme.TextColors.tertiary)
                                .frame(width: 6, height: 6)
                            
                            Text(adminWS.isConnected ? "Live" : "Offline")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.TextColors.secondary)
                        }
                        
                        Text("•")
                            .foregroundColor(AppTheme.TextColors.tertiary)
                        
                        Text("\(adminVM.totalUsers) users")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.TextColors.secondary)
                    }
                }
                
                Spacer()
                
                // Quick stats
                HStack(spacing: 16) {
                    QuickStat(
                        title: "Online",
                        value: "\(filteredUsers.filter { $0.online }.count)",
                        color: AppTheme.AccentColors.success
                    )
                    
                    QuickStat(
                        title: "Suspended",
                        value: "\(filteredUsers.filter { $0.status == "suspended" }.count)",
                        color: AppTheme.AccentColors.error
                    )
                }
            }
            
            // Search and filters
            HStack(spacing: 16) {
                // Search bar
                GlassSearchBar(text: $searchText)
                    .frame(maxWidth: 400)
                
                Spacer()
                
                // Filter chips
                HStack(spacing: 8) {
                    ForEach(UserFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter,
                            color: filter.color
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                
                // Sort picker
                Menu {
                    ForEach(UserSort.allCases, id: \.self) { sort in
                        Button(sort.rawValue) {
                            selectedSort = sort
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Sort: \(selectedSort.rawValue)")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.TextColors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.SurfaceColors.base)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            if adminVM.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(.top, 100)
            } else if let error = adminVM.errorMessage {
                Text(error)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.AccentColors.error)
                    .padding(.top, 100)
            } else {
                // Users table
                usersTable
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Users Table
    
    private var usersTable: some View {
        VStack(spacing: 0) {
            // Table container with glassmorphism
            VStack(spacing: 0) {
                // Table header
                tableHeader
                
                // Table rows
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredUsers) { user in
                            UserTableRow(
                                user: user,
                                onView: {
                                    selectedUser = user
                                    showUserDetails = true
                                },
                                onSuspend: {
                                    Task {
                                        await adminVM.suspendUser(
                                            userId: user.id,
                                            suspended: user.status != "suspended",
                                            reason: nil
                                        )
                                    }
                                }
                            )
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.SurfaceColors.base)
            )
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Table Header
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            // Avatar column
            Text("")
                .frame(width: 60)
            
            // Name column
            Text("User")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.secondary)
                .frame(minWidth: 150, alignment: .leading)
            
            Spacer()
            
            // Email column
            Text("Email")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.secondary)
                .frame(minWidth: 200, alignment: .leading)
            
            Spacer()
            
            // Role column
            Text("Role")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.secondary)
                .frame(width: 80, alignment: .center)
            
            // Last Active column
            Text("Last Active")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.secondary)
                .frame(width: 120, alignment: .center)
            
            // Actions column (right side)
            Text("Actions")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.secondary)
                .frame(width: 140, alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppTheme.SurfaceColors.base)
    }
    
    // MARK: - Helper Methods
    
    private func loadUsers() async {
        await adminVM.loadUsers(
            page: currentPage,
            filter: selectedFilter.apiValue,
            sort: selectedSort.apiValue
        )
    }
}

// MARK: - Glass Search Bar

struct GlassSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.TextColors.tertiary)
            
            TextField("Search users...", text: $text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.TextColors.primary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.TextColors.tertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.SurfaceColors.base)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : AppTheme.TextColors.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? color.opacity(0.8) : AppTheme.SurfaceColors.base)
                )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Quick Stat

struct QuickStat: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - User Table Row

struct UserTableRow: View {
    let user: AdminUser
    let onView: () -> Void
    let onSuspend: () -> Void
    
    @State private var isHovered = false
    
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
        HStack(spacing: 0) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let url = avatarURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        default:
                            defaultAvatar
                        }
                    }
                } else {
                    defaultAvatar
                }
                
                if user.online {
                    Circle()
                        .fill(AppTheme.AccentColors.success)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(AppTheme.BackgroundColors.primary, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }
            .frame(width: 60)
            
            // Name and username
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(user.name ?? "Unknown")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.primary)
                    
                    // Show suspended badge if suspended
                    if user.status == "suspended" {
                        Text("SUSPENDED")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.AccentColors.error)
                            )
                    }
                }
                
                Text("@\(user.name?.lowercased().replacingOccurrences(of: " ", with: "") ?? "unknown")")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
            .frame(minWidth: 150, alignment: .leading)
            
            Spacer()
            
            // Email
            Text(user.email ?? "No email")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.secondary)
                .frame(minWidth: 200, alignment: .leading)
            
            Spacer()
            
            // Role
            Text(user.userRole?.rawValue.capitalized ?? "User")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(user.userRole?.rawValue == "ADMIN" ? Color.orange : AppTheme.AccentColors.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill((user.userRole?.rawValue == "ADMIN" ? Color.orange : AppTheme.AccentColors.primary).opacity(0.15))
                )
                .frame(width: 80, alignment: .center)
            
            // Last Active
            Text(formatLastActive(user.lastActive))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.tertiary)
                .frame(width: 120, alignment: .center)
            
            // Actions (right side) - Text buttons instead of icons
            HStack(spacing: 8) {
                // View button
                Button(action: onView) {
                    Text("View")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.AccentColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.AccentColors.primary.opacity(0.15))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Suspend/Activate button
                Button(action: onSuspend) {
                    Text(user.status == "suspended" ? "Activate" : "Suspend")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(user.status == "suspended" ? AppTheme.AccentColors.success : AppTheme.AccentColors.error)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill((user.status == "suspended" ? AppTheme.AccentColors.success : AppTheme.AccentColors.error).opacity(0.15))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: 140, alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(isHovered ? AppTheme.SurfaceColors.base.opacity(0.5) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [AppTheme.AccentColors.primary.opacity(0.3), AppTheme.AccentColors.primary.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.TextColors.secondary)
            )
    }
    
    private func formatLastActive(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        
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

// MARK: - User Detail Panel

struct UserDetailPanel: View {
    @Environment(\.dismiss) var dismiss
    let user: AdminUser
    @ObservedObject var adminVM: AdminViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Black background like other screens
                AppTheme.BackgroundColors.primary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // User header
                        userHeaderSection
                        
                        // Stats cards
                        statsSection
                        
                        // Recent activity
                        activitySection
                    }
                    .padding(24)
                }
            }
            .navigationTitle("User Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var userHeaderSection: some View {
        VStack(spacing: 20) {
            // Avatar and basic info
            VStack(spacing: 16) {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(AppTheme.AccentColors.primary.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                VStack(spacing: 8) {
                    Text(user.name ?? "Unknown User")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.primary)
                    
                    Text(user.email ?? "No email")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.TextColors.secondary)
                    
                    // Show suspended badge if suspended
                    if user.status == "suspended" {
                        Text("SUSPENDED")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.AccentColors.error)
                            )
                    }
                }
            }
        }
        .padding(24)
        .background(AppTheme.SurfaceColors.base)
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(title: "Messages", value: "\(user.messageCount)", color: AppTheme.AccentColors.primary)
            StatCard(title: "Role", value: user.userRole?.rawValue.capitalized ?? "User", color: Color.orange)
        }
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Information")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
            
            VStack(spacing: 12) {
                InfoRow(title: "User ID", value: user.id)
                InfoRow(title: "Joined", value: formatDate(user.createdAt))
                if let lastActive = user.lastActive {
                    InfoRow(title: "Last Active", value: formatFullDate(lastActive))
                }
            }
        }
        .padding(20)
        .background(AppTheme.SurfaceColors.base)
    }
    
    private var avatarURL: URL? {
        guard let avatar = user.avatar else { return nil }
        
        if avatar.lowercased().hasPrefix("http") {
            return URL(string: avatar)
        }
        
        let baseURL = APIClient.environment.baseURL
        let cleanPath = avatar.hasPrefix("/") ? avatar : "/\(avatar)"
        return URL(string: "\(baseURL)\(cleanPath)")
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppTheme.SurfaceColors.base)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.TextColors.tertiary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.TextColors.primary)
        }
    }
}