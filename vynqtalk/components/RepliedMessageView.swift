//
//  RepliedMessageView.swift
//  vynqtalk
//
//  Component to show the replied message inside a message bubble
//

import SwiftUI

struct RepliedMessageView: View {
    let repliedMessage: Message
    let isMe: Bool
    let currentUserId: String  // To check if replied message is from current user
    
    var body: some View {
        HStack(spacing: 8) {
            // Reply indicator line
            Rectangle()
                .fill(isMe ? Color.white.opacity(0.5) : AppTheme.AccentColors.primary.opacity(0.7))
                .frame(width: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                // Show "You" if replied message is from current user, otherwise show sender name
                Text(repliedSenderName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(isMe ? .white.opacity(0.9) : AppTheme.AccentColors.primary)
                
                Text(previewText)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(isMe ? .white.opacity(0.7) : AppTheme.TextColors.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isMe ? Color.white.opacity(0.15) : Color.black.opacity(0.1))
        )
    }
    
    private var repliedSenderName: String {
        // Check if the replied message is from the current user
        if repliedMessage.sender?.id == currentUserId {
            return "You"
        }
        // Otherwise show the sender's name
        return repliedMessage.sender?.name ?? "User"
    }
    
    private var previewText: String {
        let type = repliedMessage.type ?? .text
        
        switch type {
        case .text:
            return repliedMessage.content ?? ""
        case .image:
            return "📷 Photo"
        case .video:
            return "🎥 Video"
        case .audio:
            return "🎵 Audio"
        case .file:
            return "📎 \(repliedMessage.fileName ?? "File")"
        }
    }
}
