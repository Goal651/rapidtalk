//
//  MessageBubble.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//
import SwiftUI

struct MessageBubble: View {
    let message: Message
    // Placeholder for the current user's ID. In a real app, this would come from an AuthViewModel or similar.
    let currentUserID: Int = 1 // Assuming user with ID 1 is the current user for mock purposes

    var isMe: Bool {
        message.sender?.id == currentUserID
    }

    var formattedTime: String {
        guard let timestamp = message.timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }

    var body: some View {
        HStack {
            if isMe {
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.content ?? "")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        isMe
                        ? Color.blue.opacity(0.85)
                        : Color.white.opacity(0.12)
                    )
                    .cornerRadius(14)

                Text(formattedTime)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 6)
            }
            .frame(maxWidth: 260, alignment: isMe ? .trailing : .leading)

            if !isMe {
                Spacer()
            }
        }
    }
}
