//
//  SuspensionAlert.swift
//  vynqtalk
//
//  User suspension alert overlay
//

import SwiftUI

struct SuspensionAlert: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var wsM: WebSocketManager
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            // Alert Card
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(AppTheme.AccentColors.error)
                
                // Content
                VStack(spacing: 12) {
                    Text("Account Suspended")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.primary)
                    
                    Text("Your account has been suspended by an administrator. Please contact support for more information.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                
                // Sign Out Button
                Button(action: {
                    wsM.disconnect()
                    authVM.logout()
                }) {
                    Text("Sign Out")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.Layout.buttonHeight)
                        .background(AppTheme.AccentColors.error)
                        .cornerRadius(AppTheme.Layout.cornerRadiusButton)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.BackgroundColors.tertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppTheme.AccentColors.error.opacity(0.3), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 32)
            .shadow(
                color: AppTheme.AccentColors.error.opacity(0.3),
                radius: 30,
                y: 15
            )
        }
    }
}
