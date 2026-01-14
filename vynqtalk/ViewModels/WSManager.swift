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

struct WebSocketResponse: Decodable {
    let success: Bool
    let data: WebSocketData?
    let message: String
}

enum WebSocketData: Decodable {
    case message(Message)
    case userStatus(UserStatus)
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let message = try? container.decode(Message.self) {
            self = .message(message)
        } else if let status = try? container.decode(UserStatus.self) {
            self = .userStatus(status)
        } else {
            self = .unknown
        }
    }
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
    
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var reconnectTimer: Timer?
    
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
        guard response.success, let data = response.data else {
            #if DEBUG
            print("⚠️ WebSocket response not successful: \(response.message)")
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
                self?.userStatusUpdate = status
                #if DEBUG
                print("✅ WebSocket: User \(status.userId) is \(status.online ? "online" : "offline")")
                #endif
                
            case .unknown:
                #if DEBUG
                print("⚠️ WebSocket: Unknown data type")
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
