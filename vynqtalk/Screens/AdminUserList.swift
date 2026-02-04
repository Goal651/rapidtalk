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
        if !searchText.isEmpty {
            let lowerSearch = searchText.lowercased()
            users = users.filter { user in
                let nameMatches =
                    user.name?.lowercased().contains(lowerSearch) ?? false
                let emailMatches =
                    user.email?.lowercased().contains(lowerSearch) ?? false
                return nameMatches || emailMatches
            }
        }
        return users
    }

    var body: some View {
        baseView
            .refreshable {
                await loadUsers()
            }
            .sheet(isPresented: $showUserDetails) {
                if let user = selectedUser {
                    AdminUserDetails(user: user)
                }
            }
    }

    private var baseView: some View {
        content
            .navigationTitle("Manage Users")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: handleOnAppear)
            .onDisappear(perform: handleOnDisappear)
            .onChange(of: adminWS.userStatusUpdate) { _ in
                handleUserStatusUpdate(adminWS.userStatusUpdate)
            }
            .onChange(of: adminWS.messageUpdate) { _ in
                handleMessageUpdate(adminWS.messageUpdate)
            }
            .onChange(of: adminWS.newUser) { _ in
                handleNewUser(adminWS.newUser)
            }
            .onChange(of: adminWS.suspendUpdate) { _ in
                handleSuspendUpdate(adminWS.suspendUpdate)
            }
            .onChange(of: selectedFilter) { _ in
                Task { await loadUsers() }
            }
            .onChange(of: selectedSort) { _ in
                Task { await loadUsers() }
            }
    }

    private func handleOnAppear() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            appeared = true
        }
        Task { await loadUsers() }
    }

    private func handleOnDisappear() {
        adminWS.disconnect()
    }

    // MARK: - Load Users
    private func loadUsers() async {
        await adminVM.loadUsers(
            page: 1,
            filter: selectedFilter.apiValue,
            sort: selectedSort.apiValue
        )
        adminWS.connect()
    }

    // MARK: - Event Handlers
    private func handleUserStatusUpdate(_ update: AdminUserStatusUpdate?) {
        if let u = update { adminVM.handleUserStatusUpdate(u) }
    }
    
    private func handleMessageUpdate(_ update: AdminMessageUpdate?) {
        if let u = update { adminVM.handleMessageUpdate(u) }
    }
    
    private func handleNewUser(_ user: AdminUser?) {
        if let u = user { adminVM.handleNewUser(u) }
    }
    
    private func handleSuspendUpdate(_ update: AdminSuspendUpdate?) {
        if let u = update { adminVM.handleSuspendUpdate(u) }
    }

    private var content: some View {
        ZStack {
            AppTheme.GradientColors.deepBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                searchAndFiltersSection
                userTableSection
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
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
                    .fill(
                        adminWS.isConnected
                            ? AppTheme.AccentColors.success : .gray
                    )
                    .frame(width: 8, height: 8)
                Text(
                    adminWS.isConnected
                        ? "Real-time updates active" : "Connecting..."
                )
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Search & Filters
    private var searchAndFiltersSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search users...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(UserFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) { selectedFilter = filter }
                    }
                }
                .padding(.horizontal, 24)
            }
            HStack {
                Text("Sort by:")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Picker("Sort", selection: $selectedSort) {
                    ForEach(UserSort.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.menu).tint(AppTheme.AccentColors.primary)
                Spacer()
            }.padding(.horizontal, 24)
        }
        .padding(.bottom, 16)
    }

    // MARK: - User Table
    private var userTableSection: some View {
        AdminUserTable(
            users: filteredUsers,
            action: { user in
                selectedUser = user
                showUserDetails = true
            },
            suspend: { user, suspended in
                Task {
                    await adminVM.suspendUser(
                        userId: user.id,
                        suspended: suspended
                    )
                }
            }
        )
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
                        .fill(
                            isSelected
                                ? AppTheme.AccentColors.primary
                                : .white.opacity(0.1)
                        )
                )
        }
        .animation(
            .spring(response: 0.3, dampingFraction: 0.7),
            value: isSelected
        )
    }
}

// MARK: - Admin User Table
struct AdminUserTable: View {
    let users: [AdminUser]
    let action: (AdminUser) -> Void
    let suspend: (AdminUser, Bool) -> Void
    var body: some View {
        VStack(spacing: 0) {
            // Headers
            HStack {
                Text("User").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7)).frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                Text("Role").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7)).frame(
                        width: 100,
                        alignment: .center
                    )
                Text("Status").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7)).frame(
                        width: 80,
                        alignment: .center
                    )
                Text("Actions").font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7)).frame(
                        width: 120,
                        alignment: .center
                    )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.05))

            Divider().background(Color.white.opacity(0.1))

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(users) { user in
                        AdminUserRow(
                            user: user,
                            action: action,
                            suspend: suspend
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(AppTheme.GradientColors.deepBlack)
        .cornerRadius(16)
        .padding()
    }
}

// MARK: - Avatar Helper
struct AvatarView: View {
    let url: String?

    var body: some View {

        if let u = url,
            let url = URL(string: "\(APIEnvironment.development.baseURL)\(u)")
        {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()

                default:
                    Circle().fill(Color.gray.opacity(0.3)).overlay(
                        Image(systemName: "person.fill").foregroundColor(.white)
                    )
                }
            }.clipShape(Circle())
        } else {
            Circle().fill(Color.gray.opacity(0.3)).overlay(
                Image(systemName: "person.fill").foregroundColor(.white)
            )
        }
    }
}

struct AdminUserRow: View {
    let user: AdminUser
    let action: (AdminUser) -> Void
    let suspend: (AdminUser, Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            userInfo
            role
            status
            actions
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.02))
        )
    }

    private var userInfo: some View {
        HStack(spacing: 12) {
            AvatarView(url: user.avatar)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.name ?? "Unknown")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(user.email ?? "No email")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var role: some View {
        Text(user.userRole?.rawValue ?? "-")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .frame(width: 100)
    }

    private var status: some View {
        Text(user.status.capitalized)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(
                user.status.lowercased() == "active"
                    ? AppTheme.AccentColors.success
                    : AppTheme.AccentColors.error
            )
            .frame(width: 80)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                action(user)
            } label: {
                Image(systemName: "eye")
            }

            Button {
                suspend(user, user.status.lowercased() == "active")
            } label: {
                Text(
                    user.status.lowercased() == "suspended"
                        ? "Activate" : "Suspend"
                )
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(
                        user.status.lowercased() == "suspended"
                            ? AppTheme.AccentColors.success
                            : AppTheme.AccentColors.error
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .frame(width: 120)
    }
}
