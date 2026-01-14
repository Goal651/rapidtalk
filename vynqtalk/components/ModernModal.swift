//
//  ModernModal.swift
//  vynqtalk
//
//  Modern modal component matching onboarding design
//

import SwiftUI

struct ModernModal: View {
    let title: String
    let description: String
    let onClose: () -> Void
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            // Modal Card
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(AppTheme.AccentColors.error)
                    .scaleEffect(appeared ? 1 : 0.5)
                
                // Content
                VStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                
                // Close Button
                ModernButton(
                    title: "OK",
                    style: .primary,
                    action: onClose
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.GradientColors.deepBlack)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(
                        color: .black.opacity(0.3),
                        radius: 30,
                        y: 15
                    )
            )
            .padding(.horizontal, 40)
            .scaleEffect(appeared ? 1 : 0.8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}