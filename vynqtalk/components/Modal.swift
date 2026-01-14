//
//  Modal.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//
import SwiftUI

struct ModalView: View {
    var title: String
    var description: String
    var onClose: () -> Void
    
    @State private var appeared: Bool = false
    
    var body: some View {
        ZStack {
            // Blur layer only
            AppTheme.GradientColors.deepNavyBlack.opacity(0.4)
                .ignoresSafeArea()
                .opacity(appeared ? 1 : 0)
                .onTapGesture {
                    onClose() // dismiss when tapping outside
                }

            // Centered modal card
            VStack(spacing: AppTheme.Spacing.l) {
                Text(title)
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.TextColors.primary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.TextColors.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    onClose()
                }) {
                    Text("Close")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.TextColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.AccentColors.primary)
                        .cornerRadius(AppTheme.CornerRadius.m)
                        .shadow(color: AppTheme.AccentColors.primary.opacity(0.4), radius: 10, y: 4)
                }
            }
            .padding(AppTheme.Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl)
                    .fill(AppTheme.GradientColors.deepNavyBlack.opacity(0.85))
                    .shadow(color: AppTheme.GradientColors.deepNavyBlack.opacity(0.5), radius: 20, y: 10)
            )
            .padding(.horizontal, AppTheme.Spacing.xl)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(AppTheme.AnimationCurves.spring) {
                appeared = true
            }
        }
    }
}
