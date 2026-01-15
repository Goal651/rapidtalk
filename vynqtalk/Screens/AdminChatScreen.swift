//
//  AdminChatScreen.swift
//  vynqtalk
//
//  Admin chat screen - allows admins to chat as regular users
//

import SwiftUI

struct AdminChatScreen: View {
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            AppTheme.GradientColors.deepBlack
                .ignoresSafeArea()
            
            // Use the responsive home screen (same as regular users)
            ResponsiveHomeScreen()
        }
        .navigationBarBackButtonHidden()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}
