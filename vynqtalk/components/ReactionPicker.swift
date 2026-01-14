//
//  ReactionPicker.swift
//  vynqtalk
//
//  Emoji reaction picker for messages
//

import SwiftUI

struct ReactionPicker: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    let emojis = ["❤️", "👍", "😂", "😮", "😢", "😡", "🔥", "🎉", "👏", "💯"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("React")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(.white.opacity(0.1)))
                }
            }
            .padding(20)
            .background(Color.black.opacity(0.5))
            
            // Emoji Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        onSelect(emoji)
                        dismiss()
                    }) {
                        Text(emoji)
                            .font(.system(size: 40))
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(.white.opacity(0.1))
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.8))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.clear)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
