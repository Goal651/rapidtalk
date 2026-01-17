//
//  UltraChatScreen.swift
//  vynqtalk
//
//  Ultra-Refined Chat Screen - Perfect Apple Quality
//  Maximum focus, zero distractions
//

import SwiftUI
import AVKit
import Foundation

struct UltraChatScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var messageVM: MessageViewModel
    @EnvironmentObject var wsM: WebSocketManager
    @Environment(\.dismiss) var dismiss
    
    let userId: String
    let userName: String
    let userAvatar: String?
    let initialLastActive: Date?
    
    @State private var messageText = ""
    @State private var appeared = false
    @State private var showMediaPicker = false
    @FocusState private var inputFocused: Bool
    
    var messages: [Message] {
        messageVM.messages.filter { message in
            (message.sender?.id == authVM.userId && message.receiver?.id == userId) ||
            (message.sender?.id == userId && message.receiver?.id == authVM.userId)
        }.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }
    }
    
    var body: some View {
        ZStack {
            // Perfect background
            UltraTheme.Backgrounds.gradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Perfect header
                ultraHeader
                
                // Perfect messages
                ultraMessages
                
                // Perfect input
                ultraInput
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(UltraTheme.Motion.gentle) {
                appeared = true
            }
        }
        .task {
            await messageVM.loadConversation(meId: authVM.userId, otherUserId: userId)
        }
    }
    
    // MARK: - Perfect Header
    
    private var ultraHeader: some View {
        HStack(spacing: UltraTheme.Layout.m) {
            // Perfect back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(UltraTheme.Accent.primary)
            }
            
            // Perfect avatar
            AsyncImage(url: userAvatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(UltraTheme.Glass.elevated)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(UltraTheme.Text.secondary)
                    )
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            // Perfect name
            Text(userName)
                .font(UltraTheme.Typography.body)
                .foregroundColor(UltraTheme.Text.primary)
            
            Spacer()
        }
        .padding(.horizontal, UltraTheme.Layout.l)
        .padding(.vertical, UltraTheme.Layout.m)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Perfect Messages
    
    private var ultraMessages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: UltraTheme.Layout.s) {
                    ForEach(messages) { message in
                        UltraMessageBubble(
                            message: message,
                            onReply: { msg in
                                // Handle reply
                            },
                            onReact: { msg, emoji in
                                wsM.sendReaction(emoji: emoji, messageId: msg.id ?? "")
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, UltraTheme.Layout.l)
                .padding(.vertical, UltraTheme.Layout.m)
            }
            .onChange(of: messages.count) { _ in
                if let lastMessage = messages.last {
                    withAnimation(UltraTheme.Motion.gentle) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Perfect Input
    
    private var ultraInput: some View {
        HStack(spacing: UltraTheme.Layout.m) {
            // Perfect media button
            Button(action: { showMediaPicker = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(UltraTheme.Accent.primary)
            }
            
            // Perfect text field
            TextField("Message", text: $messageText)
                .font(UltraTheme.Typography.body)
                .foregroundColor(UltraTheme.Text.primary)
                .focused($inputFocused)
                .padding(.horizontal, UltraTheme.Layout.m)
                .padding(.vertical, UltraTheme.Layout.s)
                .background(UltraTheme.Glass.surface, in: Capsule())
            
            // Perfect send button
            if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(UltraTheme.Accent.primary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, UltraTheme.Layout.l)
        .padding(.vertical, UltraTheme.Layout.m)
        .background(.ultraThinMaterial)
        .animation(UltraTheme.Motion.spring, value: messageText.isEmpty)
        .sheet(isPresented: $showMediaPicker) {
            UltraMediaPicker(isPresented: $showMediaPicker) { mediaItem in
                sendMediaMessage(mediaItem)
            }
        }
    }
    
    private var userAvatarURL: URL? {
        guard let avatar = userAvatar, !avatar.isEmpty else { return nil }
        return URL(string: avatar)
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        wsM.sendChatMessage(
            receiverId: userId,
            content: text,
            type: .text
        )
        
        messageText = ""
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func sendMediaMessage(_ mediaItem: MediaItem) {
        // For now, send the file name as content
        // In a real app, you would upload the media first and get a URL
        let content = mediaItem.fileName
        
        wsM.sendChatMessage(
            receiverId: userId,
            content: content,
            type: mediaItem.type
        )
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}