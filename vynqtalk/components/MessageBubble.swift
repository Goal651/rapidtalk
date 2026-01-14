//
//  MessageBubble.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//
import SwiftUI

struct MessageBubble: View {
    @EnvironmentObject var authVM: AuthViewModel
    let message: Message
    @State private var appeared = false

    var isMe: Bool {
        message.sender?.id == authVM.userId
    }

    var formattedTime: String {
        guard let timestamp = message.timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.s) {
            if isMe {
                Spacer()
                
                // Time for sent messages (left side)
                Text(formattedTime)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }

            // Message bubble
            Text(message.content ?? "")
                .foregroundColor(AppTheme.TextColors.primary)
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.m)
                .background(
                    Group {
                        if isMe {
                            // Gradient background for sent messages
                            LinearGradient(
                                colors: [
                                    AppTheme.AccentColors.primary,
                                    AppTheme.AccentColors.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            // Solid background for received messages
                            AppTheme.SurfaceColors.surfaceMedium
                        }
                    }
                )
                .cornerRadius(AppTheme.CornerRadius.l)
                .frame(maxWidth: 260, alignment: isMe ? .trailing : .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityDescription)
                .accessibilityAddTraits(.isStaticText)

            if !isMe {
                // Time for received messages (right side)
                Text(formattedTime)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.TextColors.tertiary)
                
                Spacer()
            }
        }
        // Slide-in animation for messages
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : (isMe ? 50 : -50))
        .onAppear {
            withAnimation(.easeOut(duration: AppTheme.AnimationDuration.normal)) {
                appeared = true
            }
        }
    }
    
    private var accessibilityDescription: String {
        let sender = isMe ? "You" : (message.sender?.name ?? "Unknown")
        let content = message.content ?? ""
        let time = formattedTime
        
        return "\(sender) said \(content) at \(time)"
    }
}
