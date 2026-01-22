//
//  AdminWSManager.swift
//  vynqtalk
//
//  Admin WebSocket Manager for real-time updates
//

import Foundation
import SwiftUI

// MARK: - Admin WebSocket Response

struct AdminWebSocketResponse: Decodable {
    let success: Bool
    let message: String
    let data: DataContainer?
    
    struct DataContainer: Decodable {
        // User status fields
        let userId: String?
        let online: Bool?
        let lastActive: Double?
        
        // Message update fields
        let messageCount: Int?
        
        // New user fields
        let id: String?
        let name: String?
        let email: String?
        let avatar: String?
        let userRole: String?
        let status: String?
        let createdAt: Date?
        
        // Suspend update fields
        let suspended: Bool?
        let suspendedBy: String?
        
        enum CodingKeys: String, CodingKey {
            case userId, online, lastActive
            case messageCount
            case id, name, email, avatar, userRole, status, createdAt
            case suspended, suspendedBy
        }
    }
    
    var parsedEvent: AdminWebSocketEvent? {
        guard let data = data else { return nil }
        
        // User status update
        if message == "admin_user_status",
           let userId = data.userId,
           let online = data.online {
            let lastActive: Date?
            if let timestamp = data.lastActive {
                lastActive = Date(timeIntervalSinceReferenceDate: timestamp)
            } else {
                lastActive = nil
            }
            return .userStatus(AdminUserStatusUpdate(
                userId: userId,
                online: online,
                lastActive: lastActive
            ))
        }
        
        // Message sent update
        if message == "admin_message_sent",
           let userId = data.userId,
           let messageCount = data.messageCount {
            return .messageSent(AdminMessageUpdate(
                userId: userId,
                messageCount: messageCount
            ))
        }
        
        // New user registered
        if message == "admin_new_user",
           let id = data.id,
           let name = data.name,
           let email = data.email {
            let user = AdminUser(
                id: id,
                name: name,
                email: email,
                avatar: data.avatar,
                userRole: UserRole(rawValue: data.userRole ?? "user"),
                status: data.status ?? "active",
                online: false,
                lastActive: nil,
                createdAt: data.createdAt,
                messageCount: data.messageCount ?? 0,
                suspendedAt: nil
            )
            return .newUser(user)
        }
        
        // User suspended
        if message == "admin_user_suspended",
           let userId = data.userId,
           let suspended = data.suspended,
           let suspendedBy = data.suspendedBy {
            return .userSuspended(AdminSuspendUpdate(
                userId: userId,
                suspended: suspended,
                suspendedBy: suspendedBy
            ))
        }
        
        return .unknown
    }
}

// MARK: - Admin WebSocket Manager

final class AdminWSManager: ObservableObject {
    private var task: URLSessionWebSocketTask?
    @Published var isConnected = false
    @Published var userStatusUpdate: AdminUserStatusUpdate?
    @Published var messageUpdate: AdminMessageUpdate?
    @Published var newUser: AdminUser?
    @Published var suspendUpdate: AdminSuspendUpdate?
    
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var reconnectTimer: Timer?
    
    // MARK: - Connection
    
    func connect() {
        guard let token = APIClient.shared.getAuthToken() else {
            #if DEBUG
            print("❌ Admin WebSocket: No auth token available")
            #endif
            return
        }
        
        let wsURL = APIClient.environment.wsURL
        guard let url = URL(string: "\(wsURL)/ws/admin?token=\(token)") else {
            #if DEBUG
            print("❌ Admin WebSocket: Invalid URL")
            #endif
            return
        }
        
        task = URLSession.shared.webSocketTask(with: url)
        task?.resume()
        isConnected = true
        reconnectAttempts = 0
        
        #if DEBUG
        print("🔌 Admin WebSocket: Connecting to \(wsURL)/ws/admin")
        #endif
        
        receiveMessage()
    }
    
    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        isConnected = false
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        #if DEBUG
        print("🔌 Admin WebSocket: Disconnected")
        #endif
    }
    
    // MARK: - Receiving Messages
    
    private func receiveMessage() {
        task?.receive { [weak self] result in
            guard let self = self else { return }
            print(result)
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage() // Continue listening
                
            case .failure(let error):
                #if DEBUG
                print("❌ Admin WebSocket error: \(error.localizedDescription) and \(error)")
                #endif
                
                DispatchQueue.main.async {
                    self.isConnected = false
                }
                
                // Attempt reconnection
                self.attemptReconnection()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            #if DEBUG
            print("📨 Admin WebSocket received: \(text)")
            #endif
            
            guard let data = text.data(using: .utf8) else { return }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let response = try decoder.decode(AdminWebSocketResponse.self, from: data)
                handleWebSocketResponse(response)
            } catch {
                #if DEBUG
                print("❌ Failed to decode Admin WebSocket message: \(error)")
                #endif
            }
            
        case .data(let data):
            #if DEBUG
            print("📨 Admin WebSocket received binary data: \(data.count) bytes")
            #endif
            
        @unknown default:
            break
        }
    }
    
    private func handleWebSocketResponse(_ response: AdminWebSocketResponse) {
        guard response.success else {
            #if DEBUG
            print("⚠️ Admin WebSocket response not successful: \(response.message)")
            #endif
            return
        }
        
        guard let event = response.parsedEvent else {
            #if DEBUG
            print("⚠️ Admin WebSocket: Could not parse event for message type: \(response.message)")
            #endif
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            switch event {
            case .userStatus(let update):
                self?.userStatusUpdate = update
                #if DEBUG
                print("✅ Admin WebSocket: User \(update.userId) is \(update.online ? "online" : "offline")")
                #endif
                
            case .messageSent(let update):
                self?.messageUpdate = update
                #if DEBUG
                print("✅ Admin WebSocket: User \(update.userId) sent message (increment by \(update.messageCount))")
                #endif
                
            case .newUser(let user):
                self?.newUser = user
                #if DEBUG
                print("✅ Admin WebSocket: New user registered: \(user.name ?? "Unknown")")
                #endif
                
            case .userSuspended(let update):
                self?.suspendUpdate = update
                #if DEBUG
                print("✅ Admin WebSocket: User \(update.userId) suspended: \(update.suspended)")
                #endif
                
            case .unknown:
                #if DEBUG
                print("⚠️ Admin WebSocket: Unknown event type")
                #endif
            }
        }
    }
    
    // MARK: - Reconnection
    
    private func attemptReconnection() {
        guard reconnectAttempts < maxReconnectAttempts else {
            #if DEBUG
            print("❌ Admin WebSocket: Max reconnection attempts reached")
            #endif
            return
        }
        
        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * 2.0, 10.0) // Exponential backoff, max 10s
        
        #if DEBUG
        print("🔄 Admin WebSocket: Attempting reconnection in \(delay)s (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect()
        }
    }
}
