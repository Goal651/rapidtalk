//
//  MessageViewModel.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//

import Foundation
import SwiftUI


final class MessageViewModel: ObservableObject {
    
    @Published private(set) var messages: [Message] = []
    
    init() {
        loadMockMessages()
    }
    
    // Add new message
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Placeholder for current user
        let currentUser = User(id: 1, name: "Me", avatar: "", password: "", email: "me@example.com", userRole: .user, status: "online", bio: "", lastActive: Date(), createdAt: Date(), latestMessage: nil, unreadMessages: [], online: true)

        let message = Message(id: Int.random(in: 1000...9999),
                              content: content,
                              type: .text,
                              sender: currentUser,
                              receiver: nil, // This would be set to another user in a real chat
                              timestamp: Date(),
                              fileName: "",
                              edited: false,
                              reactions: [],
                              replyTo: nil)

        messages.append(message)
    }

    // Return messages
    func getMessages() -> [Message] {
        messages
    }

    // Mock data
    private func loadMockMessages() {
        let user1 = User(id: 1, name: "Me", avatar: "", password: "", email: "me@example.com", userRole: .user, status: "online", bio: "", lastActive: Date(), createdAt: Date(), latestMessage: nil, unreadMessages: [], online: true)
        let user2 = User(id: 2, name: "Friend", avatar: "", password: "", email: "friend@example.com", userRole: .user, status: "online", bio: "", lastActive: Date(), createdAt: Date(), latestMessage: nil, unreadMessages: [], online: true)

        messages = [
            Message(id: 1, content: "Hey 👋", type: .text, sender: user2, receiver: user1, timestamp: Date().addingTimeInterval(-300), fileName: "", edited: false, reactions: [], replyTo: nil),
            Message(id: 2, content: "Hi! How are you?", type: .text, sender: user1, receiver: user2, timestamp: Date().addingTimeInterval(-240), fileName: "", edited: false, reactions: [], replyTo: nil),
            Message(id: 3, content: "I'm building Vynqtalk 😄", type: .text, sender: user2, receiver: user1, timestamp: Date().addingTimeInterval(-180), fileName: "", edited: false, reactions: [], replyTo: nil),
            Message(id: 4, content: "Nice, looks clean.", type: .text, sender: user1, receiver: user2, timestamp: Date().addingTimeInterval(-120), fileName: "", edited: false, reactions: [], replyTo: nil)
        ]
    }
    
    // Time formatter
    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
}
