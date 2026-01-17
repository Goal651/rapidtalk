//
//  PremiumMessageBubble.swift
//  vynqtalk
//
//  Premium Message Bubble - Apple Quality Design
//  Glass effects with smooth animations
//

import SwiftUI
import AVKit

struct PremiumMessageBubble: View {
    @EnvironmentObject var authVM: AuthViewModel
    let message: Message
    let onReply: (Message) -> Void
    let onReact: (Message, String) -> Void
    
    @State private var appeared = false
    @State private var showImageViewer = false
    @State private var showReactionPicker = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showQuickReaction = false
    
    var isMe: Bool {
        message.sender?.id == authVM.userId
    }
    
    var formattedTime: String {
        guard let timestamp = message.timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    var messageType: MessageType {
        message.type ?? .text
    }
    
    var fileURL: URL? {
        guard let content = message.content else { return nil }
        
        if content.lowercased().hasPrefix("http") {
            return URL(string: content)
        }
        
        let baseURL = APIClient.environment.baseURL
        let cleanPath = content.hasPrefix("/") ? content : "/\(content)"
        return URL(string: "\(baseURL)\(cleanPath)")
    }
    
    private var hasValidReply: Bool {
        guard let replyTo = message.replyTo else { return false }
        return replyTo.content != nil && !replyTo.content!.isEmpty
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.width
                
                if isMe {
                    if translation < 0 {
                        swipeOffset = max(translation, -80)
                        if translation < -30 {
                            showQuickReaction = true
                        }
                    }
                } else {
                    if translation > 0 {
                        swipeOffset = min(translation, 80)
                        if translation > 30 {
                            showQuickReaction = true
                        }
                    }
                }
            }
            .onEnded { value in
                let translation = value.translation.width
                let threshold: CGFloat = 60
                
                if (isMe && translation < -threshold) || (!isMe && translation > threshold) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onReply(message)
                }
                
                withAnimation(AppTheme.Animations.spring) {
                    swipeOffset = 0
                    showQuickReaction = false
                }
            }
    }
    
    // MARK: - Quick Reaction Button
    
    private var quickReactionButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            showReactionPicker = true
            
            withAnimation(AppTheme.Animations.spring) {
                swipeOffset = 0
                showQuickReaction = false
            }
        }) {
            Image(systemName: "heart.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.3, blue: 0.5),
                                    Color(red: 1.0, green: 0.2, blue: 0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: Color(red: 1.0, green: 0.3, blue: 0.5).opacity(0.4),
                    radius: 8,
                    y: 2
                )
        }
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: AppTheme.Layout.spacing12) {
            if isMe {
                Spacer()
                
                quickReactionButton
                    .opacity(showQuickReaction ? 1 : 0)
                    .scaleEffect(showQuickReaction ? 1 : 0.5)
                    .animation(AppTheme.Animations.spring, value: showQuickReaction)
            }
            
            // Message bubble with time
            VStack(alignment: isMe ? .trailing : .leading, spacing: 6) {
                Group {
                    switch messageType {
                    case .text:
                        premiumTextMessage
                    case .image:
                        premiumImageMessage
                    case .video:
                        premiumVideoMessage
                    case .file, .audio:
                        premiumFileMessage
                    }
                }
                .frame(maxWidth: AppTheme.Layout.messageBubbleMaxWidth, alignment: isMe ? .trailing : .leading)
                .offset(x: swipeOffset)
                .gesture(swipeGesture)
                .contextMenu {
                    Button(action: {
                        onReply(message)
                    }) {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                    }
                    
                    Button(action: {
                        showReactionPicker = true
                    }) {
                        Label("React", systemImage: "face.smiling")
                    }
                }
                
                // Reactions
                if let reactions = message.reactions, !reactions.isEmpty {
                    ReactionsView(reactions: reactions, currentUserId: authVM.userId)
                }
                
                // Time
                Text(formattedTime)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.TextColors.quaternary)
                    .padding(.horizontal, 4)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription)
            
            if !isMe {
                quickReactionButton
                    .opacity(showQuickReaction ? 1 : 0)
                    .scaleEffect(showQuickReaction ? 1 : 0.5)
                    .animation(AppTheme.Animations.spring, value: showQuickReaction)
                
                Spacer()
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : (isMe ? 50 : -50))
        .onAppear {
            withAnimation(AppTheme.Animations.cardAppear) {
                appeared = true
            }
        }
        .sheet(isPresented: $showImageViewer) {
            if let url = fileURL {
                PremiumImageViewer(imageURL: url)
            }
        }
        .sheet(isPresented: $showReactionPicker) {
            ReactionPicker { emoji in
                onReact(message, emoji)
            }
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Text Message
    
    private var premiumTextMessage: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hasValidReply, let repliedMsg = message.replyTo {
                PremiumRepliedMessageView(
                    repliedMessage: repliedMsg,
                    isMe: isMe,
                    currentUserId: authVM.userId
                )
                .padding(.bottom, AppTheme.Layout.spacing12)
            }
            
            Text(message.content ?? "")
                .font(AppTheme.Typography.bodyMedium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(AppTheme.Layout.spacing20)
        .background(messageBubbleBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: AppTheme.Layout.messageBubbleRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.messageBubbleRadius)
                .stroke(messageBubbleBorder, lineWidth: 0.5)
        )
        .shadow(
            color: isMe ? AppTheme.AccentColors.primary.opacity(0.3) : Color.black.opacity(0.2),
            radius: isMe ? 12 : 8,
            y: 4
        )
    }
    
    // MARK: - Image Message
    
    private var premiumImageMessage: some View {
        Button(action: {
            showImageViewer = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                if hasValidReply, let repliedMsg = message.replyTo {
                    PremiumRepliedMessageView(
                        repliedMessage: repliedMsg,
                        isMe: isMe,
                        currentUserId: authVM.userId
                    )
                    .padding(AppTheme.Layout.spacing12)
                }
                
                if let url = fileURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 240, height: 240)
                                .clipped()
                        case .failure:
                            imagePlaceholder(icon: "photo", text: "Failed to load")
                        case .empty:
                            imagePlaceholder(icon: "photo", text: "Loading...")
                        @unknown default:
                            imagePlaceholder(icon: "photo", text: "Unknown")
                        }
                    }
                } else {
                    imagePlaceholder(icon: "photo", text: "Invalid URL")
                }
            }
            .background(messageBubbleBackground)
            .clipShape(
                RoundedRectangle(cornerRadius: AppTheme.Layout.messageBubbleRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Layout.messageBubbleRadius)
                    .stroke(messageBubbleBorder, lineWidth: 0.5)
            )
            .shadow(
                color: isMe ? AppTheme.AccentColors.primary.opacity(0.3) : Color.black.opacity(0.2),
                radius: isMe ? 12 : 8,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func imagePlaceholder(icon: String, text: String) -> some View {
        VStack(spacing: AppTheme.Layout.spacing16) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(AppTheme.TextColors.tertiary)
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.TextColors.tertiary)
        }
        .frame(width: 240, height: 240)
    }
    
    // MARK: - Video Message
    
    private var premiumVideoMessage: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hasValidReply, let repliedMsg = message.replyTo {
                PremiumRepliedMessageView(
                    repliedMessage: repliedMsg,
                    isMe: isMe,
                    currentUserId: authVM.userId
                )
                .padding(AppTheme.Layout.spacing12)
            }
            
            if let url = fileURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(width: 240, height: 240)
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.messageBubbleRadius)
                    )
            } else {
                imagePlaceholder(icon: "video", text: "Invalid URL")
            }
        }
        .background(messageBubbleBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: AppTheme.Layout.messageBubbleRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.messageBubbleRadius)
                .stroke(messageBubbleBorder, lineWidth: 0.5)
        )
        .shadow(
            color: isMe ? AppTheme.AccentColors.primary.opacity(0.3) : Color.black.opacity(0.2),
            radius: isMe ? 12 : 8,
            y: 4
        )
    }
    
    // MARK: - File Message
    
    private var premiumFileMessage: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hasValidReply, let repliedMsg = message.replyTo {
                PremiumRepliedMessageView(
                    repliedMessage: repliedMsg,
                    isMe: isMe,
                    currentUserId: authVM.userId
                )
                .padding(.bottom, AppTheme.Layout.spacing12)
            }
            
            if messageType == .audio, let url = fileURL {
                PremiumAudioPlayer(audioURL: url, isMe: isMe)
            } else {
                HStack(spacing: AppTheme.Layout.spacing16) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(AppTheme.AccentColors.primary)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(AppTheme.AccentColors.primary.opacity(0.2))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.fileName ?? "File")
                            .font(AppTheme.Typography.bodyMedium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("File")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.TextColors.tertiary)
                    }
                    
                    Spacer()
                    
                    if let url = fileURL {
                        Link(destination: url) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(AppTheme.AccentColors.primary)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Layout.spacing20)
        .background(messageBubbleBackground)
        .clipShape(
            RoundedRectangle(cornerRadius: AppTheme.Layout.messageBubbleRadius)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.messageBubbleRadius)
                .stroke(messageBubbleBorder, lineWidth: 0.5)
        )
        .shadow(
            color: isMe ? AppTheme.AccentColors.primary.opacity(0.3) : Color.black.opacity(0.2),
            radius: isMe ? 12 : 8,
            y: 4
        )
    }
    
    // MARK: - Background & Border
    
    @ViewBuilder
    private var messageBubbleBackground: some View {
        if isMe {
            // Sent messages: Blue gradient with glass effect
            AppTheme.AccentColors.messageGradient
        } else {
            // Received messages: Glass effect
            AppTheme.GlassMaterials.thick
        }
    }
    
    private var messageBubbleBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(isMe ? 0.3 : 0.2),
                Color.white.opacity(isMe ? 0.1 : 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var accessibilityDescription: String {
        let sender = isMe ? "You" : (message.sender?.name ?? "Unknown")
        let time = formattedTime
        
        switch messageType {
        case .text:
            return "\(sender) said \(message.content ?? "") at \(time)"
        case .image:
            return "\(sender) sent an image at \(time)"
        case .video:
            return "\(sender) sent a video at \(time)"
        case .audio:
            return "\(sender) sent an audio file at \(time)"
        case .file:
            return "\(sender) sent a file at \(time)"
        }
    }
}

// MARK: - Premium Replied Message View

struct PremiumRepliedMessageView: View {
    let repliedMessage: Message
    let isMe: Bool
    let currentUserId: String
    
    var body: some View {
        HStack(spacing: AppTheme.Layout.spacing12) {
            Rectangle()
                .fill(AppTheme.AccentColors.primary)
                .frame(width: 3)
                .cornerRadius(1.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(repliedMessage.sender?.name ?? "Unknown")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.AccentColors.primary)
                
                Text(repliedMessage.content ?? "")
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.TextColors.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(AppTheme.Layout.spacing12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadiusSmall)
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Premium Audio Player

struct PremiumAudioPlayer: View {
    let audioURL: URL
    let isMe: Bool
    
    @State private var isPlaying = false
    @State private var duration: TimeInterval = 0
    @State private var currentTime: TimeInterval = 0
    
    var body: some View {
        HStack(spacing: AppTheme.Layout.spacing16) {
            Button(action: {
                // Toggle play/pause
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AppTheme.AccentColors.primary.opacity(0.3))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Voice Message")
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatDuration(duration))
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(AppTheme.TextColors.tertiary)
                }
                
                // Waveform placeholder
                HStack(spacing: 2) {
                    ForEach(0..<20) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 3, height: CGFloat.random(in: 8...24))
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Premium Image Viewer

struct PremiumImageViewer: View {
    @Environment(\.dismiss) var dismiss
    let imageURL: URL
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        if scale < 1.0 {
                                            withAnimation(AppTheme.Animations.spring) {
                                                scale = 1.0
                                                lastScale = 1.0
                                            }
                                        }
                                        if scale > 4.0 {
                                            withAnimation(AppTheme.Animations.spring) {
                                                scale = 4.0
                                                lastScale = 4.0
                                            }
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(AppTheme.Animations.spring) {
                                    if scale > 1.0 {
                                        scale = 1.0
                                        lastScale = 1.0
                                    } else {
                                        scale = 2.0
                                        lastScale = 2.0
                                    }
                                }
                            }
                    case .failure:
                        VStack(spacing: AppTheme.Layout.spacing20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.white)
                            Text("Failed to load image")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(.white)
                        }
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(AppTheme.Typography.bodyMedium)
                }
            }
        }
    }
}