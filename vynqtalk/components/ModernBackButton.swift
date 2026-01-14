//
//  ModernBackButton.swift
//  vynqtalk
//
//  Modern back button matching onboarding design
//

import SwiftUI

struct ModernBackButton: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(.white.opacity(isPressed ? 0.2 : 0.1))
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 8,
                    y: 4
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}