//
//  RegisterSuccessModal.swift
//  vynqtalk
//
//  Success modal for registration completion with animated checkmark
//

import SwiftUI

struct RegisterSuccessModal: View {
    
    // MARK: - Properties
    
    let userName: String
    let onDismiss: () -> Void
    
    // MARK: - State
    
    @State private var checkmarkScale: CGFloat = 0.0
    @State private var checkmarkRotation: Double = -180
    @State private var checkmarkOpacity: Double = 0.0
    @State private var contentOpacity: Double = 0.0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Blur Background
            AppTheme.GradientColors.deepNavyBlack.opacity(0.6)
                .ignoresSafeArea()
                .blur(radius: 10)
                .onTapGesture {
                    // Prevent dismissal by tapping outside during auto-dismiss
                }
            
            // Modal Card
            VStack(spacing: AppTheme.Spacing.l) {
                // Animated Checkmark Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.AccentColors.success)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(checkmarkScale)
                .rotationEffect(.degrees(checkmarkRotation))
                .opacity(checkmarkOpacity)
                
                // Title
                Text("Account Created!")
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.TextColors.primary)
                    .multilineTextAlignment(.center)
                    .opacity(contentOpacity)
                
                // Personalized Greeting
                Text("Welcome to VynqTalk, \(userName)! 🎉")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.TextColors.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(contentOpacity)
            }
            .padding(AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                    .fill(AppTheme.SurfaceColors.surface)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                    )
            )
            .shadow(
                color: AppTheme.GradientColors.deepNavyBlack.opacity(0.3),
                radius: 20,
                x: 0,
                y: 10
            )
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .onAppear {
            // Animate checkmark entrance
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.6)
                .delay(0.1)
            ) {
                checkmarkScale = 1.0
                checkmarkRotation = 0
                checkmarkOpacity = 1.0
            }
            
            // Animate content fade-in
            withAnimation(
                .easeOut(duration: AppTheme.AnimationDuration.normal)
                .delay(0.4)
            ) {
                contentOpacity = 1.0
            }
            
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(AppTheme.AnimationCurves.easeOut) {
                    checkmarkOpacity = 0.0
                    contentOpacity = 0.0
                }
                
                // Call dismiss after fade-out animation
                DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.AnimationDuration.normal) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Preview

struct RegisterSuccessModal_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.primaryGradient
                .ignoresSafeArea()
            
            RegisterSuccessModal(
                userName: "John Doe",
                onDismiss: { print("Modal dismissed") }
            )
        }
    }
}
