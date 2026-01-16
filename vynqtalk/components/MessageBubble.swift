//
//  MessageBubble.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//
import SwiftUI
import AVKit

struct MessageBubble: View {
    @EnvironmentObject var authVM: AuthViewModel
    let message: Message
    let onReply: (Message) -> Void
    let onReact: (Message, String) -> Void  // Now includes emoji
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
        
        // Check if it's already a full URL
        if content.lowercased().hasPrefix("http") {
            return URL(string: content)
        }
        
        // Construct full URL from relative path
        let baseURL = APIClient.environment.baseURL
        let cleanPath = content.hasPrefix("/") ? content : "/\(content)"
        return URL(string: "\(baseURL)\(cleanPath)")
    }
    
    // Check if reply message has valid content
    private var hasValidReply: Bool {
        guard let replyTo = message.replyTo else { return false }
        // Check if it has actual content or is just a placeholder
        return replyTo.content != nil && !replyTo.content!.isEmpty
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.width
                
                // Swipe left for sent messages (isMe), swipe right for received messages
                if isMe {
                    // Only allow left swipe (negative translation)
                    if translation < 0 {
                        swipeOffset = max(translation, -80)
                        if translation < -30 {
                            showQuickReaction = true
                        }
                    }
                } else {
                    // Only allow right swipe (positive translation)
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
                
                // Trigger reply if swiped far enough
                if (isMe && translation < -threshold) || (!isMe && translation > threshold) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onReply(message)
                }
                
                // Reset swipe offset with animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
            
            // Reset swipe
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.s) {
            if isMe {
                Spacer()
                
                // Quick reaction button for sent messages (left side)
                quickReactionButton
                    .opacity(showQuickReaction ? 1 : 0)
                    .scaleEffect(showQuickReaction ? 1 : 0.5)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showQuickReaction)
            }

            // Message bubble with time below
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                Group {
                    switch messageType {
                    case .text:
                        textMessageView
                    case .image:
                        imageMessageView
                    case .video:
                        videoMessageView
                    case .file, .audio:
                        fileMessageView
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
                
                // Time below the bubble
                Text(formattedTime)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.TextColors.tertiary)
                    .padding(.horizontal, 4)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription)

            if !isMe {
                // Quick reaction button for received messages (right side)
                quickReactionButton
                    .opacity(showQuickReaction ? 1 : 0)
                    .scaleEffect(showQuickReaction ? 1 : 0.5)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showQuickReaction)
                
                Spacer()
            }
        }
        // Slide-in animation for messages
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : (isMe ? 50 : -50))
        .onAppear {
            withAnimation(.easeOut(duration: AppTheme.AnimationDuration.normal)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showImageViewer) {
            if let url = fileURL {
                ImageViewer(imageURL: url)
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
    
    private var textMessageView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Show replied message if exists and has valid content
            if hasValidReply, let repliedMsg = message.replyTo {
                RepliedMessageView(repliedMessage: repliedMsg, isMe: isMe, currentUserId: authVM.userId)
                    .padding(.bottom, 8)
            }
            
            Text(message.content ?? "")
                .foregroundColor(AppTheme.TextColors.primary)
                .font(AppTheme.Typography.body)
        }
        .padding(AppTheme.Spacing.m)
        .background(messageBubbleBackground)
        .cornerRadius(AppTheme.CornerRadius.l)
        .shadow(
            color: isMe ? AppTheme.AccentColors.primary.opacity(0.3) : Color.black.opacity(0.2),
            radius: isMe ? 8 : 4,
            y: 2
        )
    }
    
    // MARK: - Image Message
    
    private var imageMessageView: some View {
        Button(action: {
            showImageViewer = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Show replied message if exists and has valid content
                if hasValidReply, let repliedMsg = message.replyTo {
                    RepliedMessageView(repliedMessage: repliedMsg, isMe: isMe, currentUserId: authVM.userId)
                        .padding(8)
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
            .cornerRadius(AppTheme.CornerRadius.l)
            .shadow(
                color: isMe ? AppTheme.AccentColors.primary.opacity(0.3) : Color.black.opacity(0.2),
                radius: isMe ? 8 : 4,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func imagePlaceholder(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(AppTheme.TextColors.tertiary)
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.TextColors.tertiary)
        }
        .frame(width: 240, height: 240)
    }
    
    // MARK: - Video Message
    
    private var videoMessageView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Show replied message if exists and has valid content
            if hasValidReply, let repliedMsg = message.replyTo {
                RepliedMessageView(repliedMessage: repliedMsg, isMe: isMe, currentUserId: authVM.userId)
                    .padding(8)
            }
            
            if let url = fileURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(width: 240, height: 240)
                    .cornerRadius(AppTheme.CornerRadius.l)
            } else {
                imagePlaceholder(icon: "video", text: "Invalid URL")
            }
        }
        .background(messageBubbleBackground)
        .cornerRadius(AppTheme.CornerRadius.l)
        .shadow(
            color: isMe ? AppTheme.AccentColors.primary.opacity(0.3) : Color.black.opacity(0.2),
            radius: isMe ? 8 : 4,
            y: 2
        )
    }
    
    // MARK: - File Message
    
    private var fileMessageView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Show replied message if exists and has valid content
            if hasValidReply, let repliedMsg = message.replyTo {
                RepliedMessageView(repliedMessage: repliedMsg, isMe: isMe, currentUserId: authVM.userId)
                    .padding(.bottom, 8)
            }
            
            if messageType == .audio, let url = fileURL {
                // Audio player for voice notes
                AudioPlayerView(audioURL: url, isMe: isMe)
            } else {
                // Regular file view
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.AccentColors.primary)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(AppTheme.AccentColors.primary.opacity(0.2)))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.fileName ?? "File")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.TextColors.primary)
                            .lineLimit(1)
                        
                        Text("File")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.TextColors.tertiary)
                    }
                    
                    Spacer()
                    
                    if let url = fileURL {
                        Link(destination: url) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.AccentColors.primary)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.m)
        .background(messageBubbleBackground)
        .cornerRadius(AppTheme.CornerRadius.l)
        .shadow(
            color: isMe ? AppTheme.AccentColors.primary.opacity(0.3) : Color.black.opacity(0.2),
            radius: isMe ? 8 : 4,
            y: 2
        )
    }
    
    // MARK: - Background
    
    private var messageBubbleBackground: some View {
        Group {
            if isMe {
                // Solid blue for sent messages
                AppTheme.MessageColors.sent
            } else {
                // Dark gray for received messages
                AppTheme.MessageColors.received
            }
        }
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

// MARK: - Image Viewer

struct ImageViewer: View {
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
                                        // Reset if zoomed out too much
                                        if scale < 1.0 {
                                            withAnimation {
                                                scale = 1.0
                                                lastScale = 1.0
                                            }
                                        }
                                        // Limit max zoom
                                        if scale > 4.0 {
                                            withAnimation {
                                                scale = 4.0
                                                lastScale = 4.0
                                            }
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
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
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                            Text("Failed to load image")
                                .foregroundColor(.white)
                        }
                    case .empty:
                        ProgressView()
                            .tint(.white)
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
                }
            }
        }
    }
}
