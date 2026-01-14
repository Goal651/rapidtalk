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
        HStack(spacing: 12) {
            // Reply indicator line
            Rectangle()
                .fill(AppTheme.AccentColors.primary)
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.sender?.name ?? "Unknown")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.AccentColors.primary)
                
                Text(previewText)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.TextColors.tertiary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.white.opacity(0.1)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.SurfaceColors.surface)
        )
    }
    
    private var previewText: String {
        let type = message.type ?? .text
        
        switch type {
        case .text:
            return message.content ?? ""
        case .image:
            return "📷 Image"
        case .video:
            return "🎥 Video"
        case .audio:
            return "🎵 Audio"
        case .file:
            return "📎 \(message.fileName ?? "File")"
        }
    }
}
