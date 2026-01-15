//
//  AdminModels.swift
//  vynqtalk
//
//  Admin dashboard models
//

import Foundation

// MARK: - Dashboard Stats

struct AdminDashboardStats: Codable {
    let totalUsers: Int
    let activeUsers: Int
    let totalMessages: Int
    let newUsersToday: Int
    let messagesLast24h: Int
}

// MARK: - Admin User (Extended User with Stats)

struct AdminUser: Codable, Identifiable {
    let id: String
    let name: String?
    let email: String?
    let avatar: String?
    let userRole: UserRole?
    let status: String  // "active" | "suspended"
    let online: Bool
    let lastActive: Date?
    let createdAt: Date?
    let messageCount: Int
    let suspendedAt: Date?
}

// MARK: - User List Response

struct AdminUserListResponse: Codable {
    let users: [AdminUser]
    let pagination: PaginationInfo
}

struct PaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalUsers: Int
}

// MARK: - Suspend User Request

struct SuspendUserRequest: Codable {
    let suspended: Bool
    let reason: String?
}

// MARK: - Admin WebSocket Events

enum AdminWebSocketEvent {
    case userStatus(AdminUserStatusUpdate)
    case messageSent(AdminMessageUpdate)
    case newUser(AdminUser)
    case userSuspended(AdminSuspendUpdate)
    case unknown
}

struct AdminUserStatusUpdate: Codable {
    let userId: String
    let online: Bool
    let lastActive: Date?
}

struct AdminMessageUpdate: Codable {
    let userId: String
    let messageCount: Int  // Increment by this amount
}

struct AdminSuspendUpdate: Codable {
    let userId: String
    let suspended: Bool
    let suspendedBy: String
}
