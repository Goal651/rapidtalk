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
    let userId: Int
    let userName: String
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.black,
                    Color.blue.opacity(0.35),
                    Color.black.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.9))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(userName)
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Text("online")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.4))
                
                // Messages
                ScrollView {
                    VStack(spacing: 12) {
                        if messageVM.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.top, 20)
                        }
                        if let err = messageVM.errorMessage {
                            Text(err)
                                .foregroundColor(.red.opacity(0.85))
                                .padding(.top, 20)
                        }
                        ForEach(messageVM.messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                
                // Input bar
                HStack(spacing: 12) {
                    TextField("Message", text: $messageText)
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    
                    Button {
//                        wsM.sendChatMessage(
//                            senderId: authVM.userId,
//                            receiverId: userId,
//                            content: messageText
//                        )
                        messageText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
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
