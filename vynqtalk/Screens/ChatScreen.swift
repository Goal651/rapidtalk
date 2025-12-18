//
//  ChatScreen.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI

struct ChatScreen: View {
    @EnvironmentObject var messageVM: MessageViewModel
    @State private var messageText: String = ""
    let userId: Int
    
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
                        Text("User \(userId)")
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
                        messageVM.sendMessage(messageText)
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
    }
}
