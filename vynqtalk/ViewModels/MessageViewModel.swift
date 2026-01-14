//
//  MessageViewModel.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//

import Foundation


final class MessageViewModel: ObservableObject {
    
    @Published private(set) var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
    }
    
    // Return messages
    func getMessages() -> [Message] {
        messages
    }

    @MainActor
    func append(_ message: Message) {
        // avoid duplicates if server echoes back the same message id
        if let id = message.id, messages.contains(where: { $0.id == id }) {
            return
        }
        messages.append(message)
    }
    
    @MainActor
    func updateMessage(_ updatedMessage: Message) {
        if let index = messages.firstIndex(where: { $0.id == updatedMessage.id }) {
            messages[index] = updatedMessage
        }
    }

    @MainActor
    func loadConversation(meId: String, otherUserId: String) async {
        guard !meId.isEmpty, !otherUserId.isEmpty else {
            errorMessage = "Invalid user ids"
            messages = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // ✅ Fixed: Use correct endpoint path
            let endpoint = APIEndpoint.conversation(user1: meId, user2: otherUserId)
            let response: APIResponse<[Message]> =
                try await APIClient.shared.get(endpoint.path)
            guard response.success, let data = response.data else {
                errorMessage = response.message
                messages = []
                return
            }
            messages = data
        } catch {
            errorMessage = error.localizedDescription
            messages = []
        }
    }
}
