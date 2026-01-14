//
//  TypingIndicator.swift
//  vynqtalk
//
//  Typing indicator with three-dot sequential bounce animation
//

import SwiftUI

struct TypingIndicator: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.s) {
            // Typing indicator bubble
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppTheme.TextColors.secondary)
                        .frame(width: 8, height: 8)
                        .offset(y: dotOffset(for: index))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, 12)
            .background(AppTheme.SurfaceColors.surfaceMedium)
            .cornerRadius(18)
            .frame(maxWidth: 260, alignment: .leading)
            
            Spacer()
        }
        .onAppear {
            // Start continuous animation
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: false)
            ) {
                animationPhase = 1
            }
        }
    }
    
    /// Calculate the vertical offset for each dot based on animation phase
    private func dotOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.2
        let phase = (animationPhase + delay).truncatingRemainder(dividingBy: 1.0)
        
        // Create a bounce effect using sine wave
        if phase < 0.5 {
            return -sin(phase * 2 * .pi) * 6
        } else {
            return 0
        }
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
