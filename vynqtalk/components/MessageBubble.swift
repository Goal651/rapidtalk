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
                            // Vibrant purple gradient for sent messages
                            LinearGradient(
                                colors: [
                                    AppTheme.MessageColors.sentStart,
                                    AppTheme.MessageColors.sentEnd
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            // Elevated dark surface for received messages
                            AppTheme.MessageColors.received
                                .overlay(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.05), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                )
                .cornerRadius(AppTheme.CornerRadius.l)
                .shadow(
                    color: isMe ? AppTheme.AccentColors.primary.opacity(0.3) : Color.black.opacity(0.2),
                    radius: isMe ? 8 : 4,
                    y: 2
                )
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
