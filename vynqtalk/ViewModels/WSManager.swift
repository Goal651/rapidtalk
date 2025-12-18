//
//  WSManager.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//
//


import SwiftStomp
import SwiftUI

class WebSocketManager: ObservableObject, SwiftStompDelegate {

    private var swiftStomp: SwiftStomp!
    @Published var messages: [String] = []
    @Published var isConnected: Bool = false
    @Published var lastError: String?

    // Connect to the STOMP WebSocket
    func connect(token: String) {
        guard let url = URL(string: "ws://10.12.73.3:8080/api/v2/ws?token=\(token)") else {
            lastError = "Invalid WebSocket URL"
            print(lastError!)
            return
        }

        // Initialize SwiftStomp
        swiftStomp = SwiftStomp(host: url)
        swiftStomp.delegate = self

        // Attempt connection with headers
        do {
            swiftStomp.connect()
        } catch {
            lastError = "Failed to connect: \(error.localizedDescription)"
            print(lastError!)
        }
    }

    // Subscribe to topics
    func subscribeToMetrics() {
        guard isConnected else { return }
        swiftStomp.subscribe(to: "/topic/metrics")
    }

    func subscribeToOnlineUsers() {
        guard isConnected else { return }
        swiftStomp.subscribe(to: "/topic/onlineUsers")
    }

    // Send message
    func send(message: String) {
        guard isConnected else {
            print("Cannot send, not connected")
            return
        }
        swiftStomp.send(body: message, to: "/app/send")
    }

    // Disconnect
    func disconnect() {
        swiftStomp.disconnect()
    }

    // MARK: - SwiftStompDelegate

    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        print("Connected to STOMP server")
        isConnected = true
        subscribeToMetrics()
        subscribeToOnlineUsers()
    }

    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        print("Disconnected from STOMP server")
        isConnected = false
    }

    func onMessageReceived(swiftStomp: SwiftStomp,
                           message: Any?,
                           messageId: String,
                           destination: String,
                           headers: [String : String]) {
        if let msgString = message as? String {
            DispatchQueue.main.async {
                self.messages.append(msgString)
            }
        }
    }

    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        print("Receipt received: \(receiptId)")
    }

    func onError(swiftStomp: SwiftStomp,
                 briefDescription: String,
                 fullDescription: String?,
                 receiptId: String?,
                 type: StompErrorType) {
        lastError = briefDescription
        print("STOMP error: \(briefDescription)")
        if let full = fullDescription { print("Full: \(full)") }
    }

    func onPing() {
        print("Ping received from STOMP server")
    }
}
