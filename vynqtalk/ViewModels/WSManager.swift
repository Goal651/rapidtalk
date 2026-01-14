//
//  WSManager.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//
//

import Foundation
import SwiftUI

// MARK: - WebSocket Message Models

struct WebSocketSendMessage: Encodable {
    let type: String  // "chat_message"
    let receiverId: String  // Changed from Int to String (UUID)
    let content: String
    let messageType: String  // "TEXT", "IMAGE", etc.
    
    init(receiverId: String, content: String, messageType: MessageType = .text) {
        self.type = "chat_message"
        self.receiverId = receiverId
        self.content = content
        self.messageType = messageType.rawValue
    }
}

struct WebSocketTypingMessage: Encodable {
    let type: String = "typing"
    let userId: String
    let receiverId: String
    let isTyping: Bool
}

struct WebSocketResponse: Decodable {
    let success: Bool
    let message: String
    let data: DataContainer?
    
    struct DataContainer: Decodable {
        // User status fields - single user update
        let userId: String?
        let online: Bool?
        let lastActive: Double?
        
        // Online users array - bulk update
        let userIds: [String]?
        
        // Typing indicator fields
        let isTyping: Bool?
        
        // Message fields
        let id: String?
        let content: String?
        let senderId: String?
        let receiverId: String?
        let sender: User?
        let receiver: User?
        let timestamp: Date?
        let type: String?
        let fileName: String?
        let edited: Bool?
        
        enum CodingKeys: String, CodingKey {
            case userId, online, lastActive, userIds
            case isTyping
            case id, content, timestamp, type, fileName, edited
            case senderId, receiverId
            case sender, receiver
        }
    }
    
    var parsedData: WebSocketData? {
        guard let data = data else { return nil }
        
        // Check if it's an online users list update
        if message == "online_users", let userIds = data.userIds {
            return .onlineUsersList(userIds)
        }
        
        // Check if it's a typing indicator
        if message == "typing",
           let userId = data.userId,
           let isTyping = data.isTyping {
            return .typing(userId: userId, isTyping: isTyping)
        }
        
        // Check if it's a single user status update
        if message == "user_status", 
           let userId = data.userId,
           let online = data.online {
            let lastActive: Date?
            if let timestamp = data.lastActive {
                lastActive = Date(timeIntervalSinceReferenceDate: timestamp)
            } else {
                lastActive = nil
            }
            return .userStatus(UserStatus(userId: userId, online: online, lastActive: lastActive))
        }
        
        // Check if it's a chat message
        if message == "new_message" || message == "chat_message",
           let id = data.id,
           let content = data.content {
            
            // Use full User objects if available, otherwise create minimal User objects from IDs
            let sender: User?
            if let fullSender = data.sender {
                sender = fullSender
            } else if let senderId = data.senderId {
                sender = User(id: senderId, name: nil, avatar: nil, password: nil, email: nil, userRole: nil, status: nil, bio: nil, lastActive: nil, createdAt: nil, latestMessage: nil, unreadMessages: nil, online: nil)
            } else {
                sender = nil
            }
            
            let receiver: User?
            if let fullReceiver = data.receiver {
                receiver = fullReceiver
            } else if let receiverId = data.receiverId {
                receiver = User(id: receiverId, name: nil, avatar: nil, password: nil, email: nil, userRole: nil, status: nil, bio: nil, lastActive: nil, createdAt: nil, latestMessage: nil, unreadMessages: nil, online: nil)
            } else {
                receiver = nil
            }
            
            let msg = Message(
                id: id,
                content: content,
                type: MessageType(rawValue: data.type ?? "TEXT") ?? .text,
                sender: sender,
                receiver: receiver,
                timestamp: data.timestamp,
                fileName: data.fileName,
                edited: data.edited,
                reactions: nil,
                replyTo: nil
            )
            return .message(msg)
        }
        
        return .unknown
    }
}

enum WebSocketData {
    case message(Message)
    case userStatus(UserStatus)
    case onlineUsersList([String])
    case typing(userId: String, isTyping: Bool)
    case unknown
}

struct UserStatus: Decodable {
    let userId: String  // Changed from Int to String (UUID)
    let online: Bool
    let lastActive: Date?
}

// MARK: - WebSocket Manager

final class WebSocketManager: ObservableObject {
    private var task: URLSessionWebSocketTask?
    @Published var isConnected = false
    @Published var incomingMessage: Message?
    @Published var userStatusUpdate: UserStatus?
    @Published var onlineUserIds: Set<String> = [] // Array of currently online user IDs
    @Published var typingUsers: [String: Bool] = [:] // userId: isTyping
    @Published var userLastActiveCache: [String: Date] = [:] // Cache last active times
    
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var reconnectTimer: Timer?
    
    // Helper to check if a user is online
    func isUserOnline(_ userId: String) -> Bool {
        return onlineUserIds.contains(userId)
    }
    
    // Helper to check if a user is typing
    func isUserTyping(_ userId: String) -> Bool {
        return typingUsers[userId] == true
    }
    
    // Helper to get last active time (from cache or provided)
    func getLastActive(for userId: String) -> Date? {
        return userLastActiveCache[userId]
    }
    
    // Update last active time in cache
    func updateLastActive(for userId: String, date: Date) {
        userLastActiveCache[userId] = date
    }
    
    // MARK: - Connection
    
    func connect() {
        guard let token = APIClient.shared.getAuthToken() else {
            #if DEBUG
            print("❌ WebSocket: No auth token available")
            #endif
            return
        }
        
        let wsURL = APIClient.environment.wsURL
        guard let url = URL(string: "\(wsURL)/ws?token=\(token)") else {
            #if DEBUG
            print("❌ WebSocket: Invalid URL")
            #endif
            return
        }
        
        task = URLSession.shared.webSocketTask(with: url)
        task?.resume()
        isConnected = true
        reconnectAttempts = 0
        
        #if DEBUG
        print("🔌 WebSocket: Connecting to \(wsURL)/ws")
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
        print("🔌 WebSocket: Disconnected")
        #endif
    }
    
    // MARK: - Receiving Messages
    
    private func receiveMessage() {
        task?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage() // Continue listening
                
            case .failure(let error):
                #if DEBUG
                print("❌ WebSocket error: \(error.localizedDescription)")
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
            print("📨 WebSocket received: \(text)")
            #endif
            
            guard let data = text.data(using: .utf8) else { return }
            
            do {
                let response = try JSONDecoder().decode(WebSocketResponse.self, from: data)
                handleWebSocketResponse(response)
            } catch {
                #if DEBUG
                print("❌ Failed to decode WebSocket message: \(error)")
                #endif
            }
            
        case .data(let data):
            #if DEBUG
            print("📨 WebSocket received binary data: \(data.count) bytes")
            #endif
            
        @unknown default:
            break
        }
    }
    
    private func handleWebSocketResponse(_ response: WebSocketResponse) {
        guard response.success else {
            #if DEBUG
            print("⚠️ WebSocket response not successful: \(response.message)")
            #endif
            return
        }
        
        guard let data = response.parsedData else {
            #if DEBUG
            print("⚠️ WebSocket: Could not parse data for message type: \(response.message)")
            #endif
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            switch data {
            case .message(let message):
                self?.incomingMessage = message
                #if DEBUG
                print("✅ WebSocket: Received message from \(message.sender?.name ?? "Unknown")")
                #endif
                
            case .userStatus(let status):
                // Update the online users set
                if status.online {
                    self?.onlineUserIds.insert(status.userId)
                } else {
                    self?.onlineUserIds.remove(status.userId)
                    
                    // Cache the last active time
                    let lastActive = status.lastActive ?? Date()
                    self?.userLastActiveCache[status.userId] = lastActive
                    
                    // If backend didn't provide lastActive, create updated status with current time
                    if status.lastActive == nil {
                        let updatedStatus = UserStatus(
                            userId: status.userId,
                            online: false,
                            lastActive: Date()
                        )
                        self?.userStatusUpdate = updatedStatus
                    } else {
                        self?.userStatusUpdate = status
                    }
                }
                
                // If user came online, also cache that they were active now
                if status.online {
                    self?.userLastActiveCache[status.userId] = Date()
                    self?.userStatusUpdate = status
                }
                
                #if DEBUG
                print("✅ WebSocket: User \(status.userId) is \(status.online ? "online" : "offline")")
                if let lastActive = status.lastActive ?? self?.userLastActiveCache[status.userId] {
                    print("   Last active: \(lastActive)")
                }
                #endif
                
            case .onlineUsersList(let userIds):
                let previousOnlineUsers = self?.onlineUserIds ?? []
                let newOnlineUsers = Set(userIds)
                
                // Find users who went offline (were online before, not online now)
                let usersWentOffline = previousOnlineUsers.subtracting(newOnlineUsers)
                
                // Update last active time for users who went offline
                let now = Date()
                for userId in usersWentOffline {
                    self?.userLastActiveCache[userId] = now
                }
                
                // Update the online users set
                self?.onlineUserIds = newOnlineUsers
                
                #if DEBUG
                print("✅ WebSocket: Received online users list (\(userIds.count) users online)")
                if !usersWentOffline.isEmpty {
                    print("   Users went offline: \(usersWentOffline.count)")
                }
                print("   Online user IDs: \(userIds.prefix(5).joined(separator: ", "))\(userIds.count > 5 ? "..." : "")")
                #endif
                
            case .typing(let userId, let isTyping):
                self?.typingUsers[userId] = isTyping
                #if DEBUG
                print("✅ WebSocket: User \(userId) is \(isTyping ? "typing" : "not typing")")
                #endif
                
            case .unknown:
                #if DEBUG
                print("⚠️ WebSocket: Unknown data type for message: \(response.message)")
                #endif
            }
        }
    }
    
    // MARK: - Sending Messages
    
    func sendChatMessage(receiverId: String, content: String, type: MessageType = .text) {
        let message = WebSocketSendMessage(
            receiverId: receiverId,
            content: content,
            messageType: type
        )
        
        guard let data = try? JSONEncoder().encode(message),
              let string = String(data: data, encoding: .utf8) else {
            #if DEBUG
            print("❌ Failed to encode message")
            #endif
            return
        }
        
        task?.send(.string(string)) { error in
            if let error = error {
                #if DEBUG
                print("❌ Failed to send message: \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("📤 WebSocket: Sent message to user \(receiverId)")
                #endif
            }
        }
    }
    
    func sendTypingIndicator(userId: String, receiverId: String, isTyping: Bool) {
        let typingMessage = WebSocketTypingMessage(
            userId: userId,
            receiverId: receiverId,
            isTyping: isTyping
        )
        
        guard let data = try? JSONEncoder().encode(typingMessage),
              let string = String(data: data, encoding: .utf8) else {
            #if DEBUG
            print("❌ Failed to encode typing indicator")
            #endif
            return
        }
        
        task?.send(.string(string)) { error in
            if let error = error {
                #if DEBUG
                print("❌ Failed to send typing indicator: \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("📤 WebSocket: Sent typing indicator (isTyping: \(isTyping)) to user \(receiverId)")
                #endif
            }
        }
    }
    
    // MARK: - Reconnection
    
    private func attemptReconnection() {
        guard reconnectAttempts < maxReconnectAttempts else {
            #if DEBUG
            print("❌ WebSocket: Max reconnection attempts reached")
            #endif
            return
        }
        
        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * 2.0, 10.0) // Exponential backoff, max 10s
        
        #if DEBUG
        print("🔄 WebSocket: Attempting reconnection in \(delay)s (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect()
        }
    }
}
