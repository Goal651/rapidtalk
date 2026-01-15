//
//  AdminViewModel.swift
//  vynqtalk
//
//  Admin dashboard data management
//

import Foundation
import SwiftUI

class AdminViewModel: ObservableObject {
    @Published var dashboardStats: AdminDashboardStats?
    @Published var users: [AdminUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Pagination
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var totalUsers = 0
    
    private let api = APIClient.shared
    
    // MARK: - Load Dashboard Stats
    
    @MainActor
    func loadDashboardStats() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: APIResponse<AdminDashboardStats> = try await api.get("/admin/dashboard")
            
            guard response.success, let stats = response.data else {
                errorMessage = response.message
                isLoading = false
                return
            }
            
            dashboardStats = stats
            isLoading = false
            
            #if DEBUG
            print("✅ Loaded dashboard stats: \(stats.totalUsers) users, \(stats.totalMessages) messages")
            #endif
            
        } catch {
            errorMessage = "Failed to load dashboard stats"
            isLoading = false
            #if DEBUG
            print("❌ Dashboard stats error: \(error)")
            #endif
        }
    }
    
    // MARK: - Load Users
    
    @MainActor
    func loadUsers(page: Int = 1, filter: String = "all", sort: String = "lastActive") async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: APIResponse<AdminUserListResponse> = try await api.get(
                "/admin/users?page=\(page)&limit=50&filter=\(filter)&sort=\(sort)"
            )
            
            guard response.success, let data = response.data else {
                errorMessage = response.message
                isLoading = false
                return
            }
            
            users = data.users
            currentPage = data.pagination.currentPage
            totalPages = data.pagination.totalPages
            totalUsers = data.pagination.totalUsers
            isLoading = false
            
            #if DEBUG
            print("✅ Loaded \(users.count) users (page \(currentPage)/\(totalPages))")
            #endif
            
        } catch {
            errorMessage = "Failed to load users"
            isLoading = false
            #if DEBUG
            print("❌ Load users error: \(error)")
            #endif
        }
    }
    
    // MARK: - Load User Details
    
    @MainActor
    func loadUserDetails(userId: String) async -> AdminUser? {
        do {
            let response: APIResponse<AdminUser> = try await api.get("/admin/users/\(userId)")
            
            guard response.success, let user = response.data else {
                errorMessage = response.message
                return nil
            }
            
            #if DEBUG
            print("✅ Loaded user details for: \(user.name ?? "Unknown")")
            #endif
            
            return user
            
        } catch {
            errorMessage = "Failed to load user details"
            #if DEBUG
            print("❌ Load user details error: \(error)")
            #endif
            return nil
        }
    }
    
    // MARK: - Suspend/Unsuspend User
    
    @MainActor
    func suspendUser(userId: String, suspended: Bool, reason: String? = nil) async -> Bool {
        do {
            let payload = SuspendUserRequest(suspended: suspended, reason: reason)
            let response: APIResponse<AdminUser> = try await api.put(
                "/admin/users/\(userId)/suspend",
                data: payload
            )
            
            guard response.success else {
                errorMessage = response.message
                return false
            }
            
            // Update user in local list
            if let index = users.firstIndex(where: { $0.id == userId }) {
                users[index] = AdminUser(
                    id: users[index].id,
                    name: users[index].name,
                    email: users[index].email,
                    avatar: users[index].avatar,
                    userRole: users[index].userRole,
                    status: suspended ? "suspended" : "active",
                    online: users[index].online,
                    lastActive: users[index].lastActive,
                    createdAt: users[index].createdAt,
                    messageCount: users[index].messageCount,
                    suspendedAt: suspended ? Date() : nil
                )
            }
            
            #if DEBUG
            print("✅ User \(userId) \(suspended ? "suspended" : "unsuspended")")
            #endif
            
            return true
            
        } catch {
            errorMessage = "Failed to \(suspended ? "suspend" : "unsuspend") user"
            #if DEBUG
            print("❌ Suspend user error: \(error)")
            #endif
            return false
        }
    }
    
    // MARK: - Real-time Updates
    
    @MainActor
    func handleUserStatusUpdate(_ update: AdminUserStatusUpdate) {
        if let index = users.firstIndex(where: { $0.id == update.userId }) {
            users[index] = AdminUser(
                id: users[index].id,
                name: users[index].name,
                email: users[index].email,
                avatar: users[index].avatar,
                userRole: users[index].userRole,
                status: users[index].status,
                online: update.online,
                lastActive: update.lastActive ?? users[index].lastActive,
                createdAt: users[index].createdAt,
                messageCount: users[index].messageCount,
                suspendedAt: users[index].suspendedAt
            )
            
            // Update active users count in dashboard
            if let stats = dashboardStats {
                let activeCount = users.filter { $0.online }.count
                dashboardStats = AdminDashboardStats(
                    totalUsers: stats.totalUsers,
                    activeUsers: activeCount,
                    totalMessages: stats.totalMessages,
                    newUsersToday: stats.newUsersToday,
                    messagesLast24h: stats.messagesLast24h
                )
            }
        }
    }
    
    @MainActor
    func handleMessageUpdate(_ update: AdminMessageUpdate) {
        if let index = users.firstIndex(where: { $0.id == update.userId }) {
            users[index] = AdminUser(
                id: users[index].id,
                name: users[index].name,
                email: users[index].email,
                avatar: users[index].avatar,
                userRole: users[index].userRole,
                status: users[index].status,
                online: users[index].online,
                lastActive: users[index].lastActive,
                createdAt: users[index].createdAt,
                messageCount: users[index].messageCount + update.messageCount,
                suspendedAt: users[index].suspendedAt
            )
            
            // Update total messages in dashboard
            if let stats = dashboardStats {
                dashboardStats = AdminDashboardStats(
                    totalUsers: stats.totalUsers,
                    activeUsers: stats.activeUsers,
                    totalMessages: stats.totalMessages + update.messageCount,
                    newUsersToday: stats.newUsersToday,
                    messagesLast24h: stats.messagesLast24h + update.messageCount
                )
            }
        }
    }
    
    @MainActor
    func handleNewUser(_ user: AdminUser) {
        // Add to beginning of list
        users.insert(user, at: 0)
        
        // Update dashboard stats
        if let stats = dashboardStats {
            dashboardStats = AdminDashboardStats(
                totalUsers: stats.totalUsers + 1,
                activeUsers: stats.activeUsers,
                totalMessages: stats.totalMessages,
                newUsersToday: stats.newUsersToday + 1,
                messagesLast24h: stats.messagesLast24h
            )
        }
    }
    
    @MainActor
    func handleSuspendUpdate(_ update: AdminSuspendUpdate) {
        if let index = users.firstIndex(where: { $0.id == update.userId }) {
            users[index] = AdminUser(
                id: users[index].id,
                name: users[index].name,
                email: users[index].email,
                avatar: users[index].avatar,
                userRole: users[index].userRole,
                status: update.suspended ? "suspended" : "active",
                online: users[index].online,
                lastActive: users[index].lastActive,
                createdAt: users[index].createdAt,
                messageCount: users[index].messageCount,
                suspendedAt: update.suspended ? Date() : nil
            )
        }
    }
}
