//
//  ReplyPreview.swift
//  vynqtalk
//
//  Reply preview component for showing the message being replied to
//

import SwiftUI

struct ReplyPreview: View {
    let message: Message
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Thin accent line
            Capsule()
                .fill(AppTheme.AccentColors.primary)
                .frame(width: 2.5, height: 32)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(message.sender?.name ?? "Unknown")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.AccentColors.primary)
                
                HStack(spacing: 3) {
                    if let typeIcon = messageTypeIcon {
                        Text(typeIcon)
                            .font(.system(size: 11))
                    }
                    
                    Text(previewText)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer(minLength: 8)
            
            // Minimal X button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onCancel()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.TextColors.tertiary)
                    .frame(width: 18, height: 18)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.SurfaceColors.base.opacity(0.6))
        )
    }
    
    private var messageTypeIcon: String? {
        let type = message.type ?? .text
        
        switch type {
        case .text:
            return nil
        case .image:
            return "📷"
        case .video:
            return "🎥"
        case .audio:
            return "🎵"
        case .file:
            return "📎"
        }
    }
    
    private var previewText: String {
        let type = message.type ?? .text
        
        switch type {
        case .text:
            return message.content ?? ""
        case .image:
            return "Image"
        case .video:
            return "Video"
        case .audio:
            return "Voice message"
        case .file:
            return message.fileName ?? "File"
        }
    }
}
