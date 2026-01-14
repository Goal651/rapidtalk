//
//  TypingIndicator.swift
//  vynqtalk
//
//  Typing indicator with three-dot sequential bounce animation
//

import SwiftUI

struct TypingIndicator: View {
    @State private var animationPhase: CGFloat = 0
    @State private var appeared: Bool = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.s) {
            // Typing indicator bubble
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppTheme.TextColors.secondary)
                        .frame(width: 8, height: 8)
                        .offset(y: dotOffset(for: index))
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, AppTheme.Spacing.m)
            .background(AppTheme.SurfaceColors.surfaceMedium)
            .cornerRadius(AppTheme.CornerRadius.l)
            .frame(maxWidth: 260, alignment: .leading)
            
            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -20)
        .onAppear {
            // Fade in animation
            withAnimation(AppTheme.AnimationCurves.componentAppearance) {
                appeared = true
            }
            
            // Start continuous dot animation
            animationPhase = 1
        }
    }
    
    /// Calculate the vertical offset for each dot based on animation phase
    private func dotOffset(for index: Int) -> CGFloat {
        return animationPhase == 1 ? -6 : 0
    }
}

// Preview
#Preview {
    ZStack {
        AppTheme.primaryGradient
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            TypingIndicator()
                .padding()
            Spacer()
        }
    }
}
