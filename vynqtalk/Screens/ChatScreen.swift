//
//  ChatScreen.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI


struct ChatScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var messageVM: MessageViewModel
    @EnvironmentObject var wsM: WebSocketManager
    @State private var messageText: String = ""
    @State private var isSendButtonPressed = false
    @State private var isOtherUserTyping = false // For typing indicator
    let userId: Int
    let userName: String
    
    var body: some View {
        ZStack {
            // Background - AnimatedGradientBackground
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Header with theme styling
                HStack(spacing: AppTheme.Spacing.m) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.TextColors.primary)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(userName)
                            .foregroundColor(AppTheme.TextColors.primary)
                            .font(AppTheme.Typography.headline)
                        
                        Text("online")
                            .foregroundColor(AppTheme.AccentColors.success)
                            .font(AppTheme.Typography.caption)
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.Spacing.m)
                .background(
                    AppTheme.GradientColors.deepNavyBlack.opacity(0.4)
                        .blur(radius: 10)
                )
                
                // Messages
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.m) {
                        if messageVM.isLoading {
                            LoadingView(style: .spinner)
                                .padding(.top, AppTheme.Spacing.l)
                        }
                        if let err = messageVM.errorMessage {
                            Text(err)
                                .foregroundColor(AppTheme.AccentColors.error)
                                .font(AppTheme.Typography.body)
                                .padding(.top, AppTheme.Spacing.l)
                        }
                        ForEach(messageVM.messages) { message in
                            MessageBubble(message: message)
                        }
                        
                        // Typing indicator
                        if isOtherUserTyping {
                            TypingIndicator()
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.vertical, AppTheme.Spacing.m)
                }
                
                // Input bar with theme styling
                HStack(spacing: AppTheme.Spacing.m) {
                    TextField("Message", text: $messageText)
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.SurfaceColors.surface)
                        .cornerRadius(AppTheme.CornerRadius.xl)
                        .foregroundColor(AppTheme.TextColors.primary)
                        .font(AppTheme.Typography.body)
                    
                    Button {
//                        wsM.sendChatMessage(
//                            senderId: authVM.userId,
//                            receiverId: userId,
//                            content: messageText
//                        )
                        messageText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(AppTheme.TextColors.primary)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(
                                    colors: [
                                        AppTheme.AccentColors.primary,
                                        AppTheme.AccentColors.primary.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                    }
                    .scaleEffect(isSendButtonPressed ? 0.9 : 1.0)
                    .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                        withAnimation(AppTheme.AnimationCurves.buttonPress) {
                            isSendButtonPressed = pressing
                        }
                    }, perform: {})
                }
                .padding(AppTheme.Spacing.m)
                .background(
                    AppTheme.GradientColors.deepNavyBlack.opacity(0.5)
                        .blur(radius: 10)
                )
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .task {
            await messageVM.loadConversation(meId: authVM.userId, otherUserId: userId)
        }
//        .onChange(of: wsM.incomingMessage?.id) { _, _ in
//            guard let m = wsM.incomingMessage else { return }
//            // only append messages that belong to this chat
//            let s = m.sender?.id ?? -1
//            let r = m.receiver?.id ?? -1
//            let me = authVM.userId
//            if (s == me && r == userId) || (s == userId && r == me) {
//                Task { @MainActor in
//                    messageVM.append(m)
//                }
//            }
//        }
    }
}
