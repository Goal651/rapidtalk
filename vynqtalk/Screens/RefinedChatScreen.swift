//
//  RefinedChatScreen.swift
//  vynqtalk
//
//  Refined Premium Chat Screen - Calmer, More Premium
//  Reduced visual noise by 20% for better focus
//

import SwiftUI
import AVKit

struct RefinedChatScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var messageVM: MessageViewModel
    @EnvironmentObject var wsM: WebSocketManager
    @Environment(\.dismiss) var dismiss
    
    @State private var messageText: String = ""
    @State private var isSendButtonPressed = false
    @State private var isOtherUserTyping = false
    @State private var userOnlineStatus: Bool = false
    @State private var userLastActive: Date?
    @State private var showUserDetails = false
    @State private var typingTimer: Timer?
    @State private var showMediaPicker = false
    @State private var isUploadingMedia = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var replyingTo: Message?
    @State private var isRecordingVoice = false
    @State private var appeared = false
    
    let userId: String
    let userName: String
    let userAvatar: String?
    let initialLastActive: Date?
    var isInSplitView: Bool = false
    
    init(userId: String, userName: String, userAvatar: String?, initialLastActive: Date? = nil, isInSplitView: Bool = false) {
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.initialLastActive = initialLastActive
        self.isInSplitView = isInSplitView
        _userLastActive = State(initialValue: initialLastActive)
    }
    
    private var lastActiveText: String {
        guard let lastActive = userLastActive else {
            return "recently"
        }
        
        let now = Date()
        let interval = now.timeIntervalSince(lastActive)
        
        return formatTimeInterval(interval)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return "now"
        }
        
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        }
        
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        }
        
        let days = Int(interval / 86400)
        return "\(days)d"
    }
    
    var body: some View {
        ZStack {
            // Calmer background - single color instead of gradient
            AppTheme.BackgroundColors.primary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Minimal header
                refinedChatHeader
                
                // Clean messages section
                refinedMessagesSection
                
                // Simplified input bar
                refinedInputBar
            }
        }
        .navigationBarBackButtonHidden(isInSplitView)
        .toolbar(isInSplitView ? .visible : .hidden, for: .tabBar)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
            
            userOnlineStatus = wsM.isUserOnline(userId)
            if let cachedLastActive = wsM.getLastActive(for: userId) {
                userLastActive = cachedLastActive
            }
        }
        .task {
            await messageVM.loadConversation(meId: authVM.userId, otherUserId: userId)
        }
        .onChange(of: wsM.incomingMessage?.id) { _, _ in
            handleIncomingMessage()
        }
        .onChange(of: wsM.onlineUserIds) { _, _ in
            handleOnlineUsersChange()
        }
        .onChange(of: wsM.userStatusUpdate?.userId) { _, _ in
            handleUserStatusUpdate()
        }
        .onChange(of: wsM.typingUsers[userId]) { _, isTyping in
            isOtherUserTyping = isTyping == true
        }
        .onChange(of: messageText) { oldValue, newValue in
            handleTypingChange(oldValue: oldValue, newValue: newValue)
        }
        .sheet(isPresented: $showUserDetails) {
            RefinedUserDetailsSheet(
                userName: userName,
                userAvatar: userAvatar,
                userId: userId,
                isOnline: userOnlineStatus,
                lastActive: userLastActive
            )
        }
        .sheet(isPresented: $showMediaPicker) {
            UltraMediaPicker(isPresented: $showMediaPicker) { mediaItem in
                sendMediaMessage(mediaItem)
            }
        }
        .onChange(of: wsM.reactionUpdate?.id) { _, _ in
            handleReactionUpdate()
        }
    }
    
    // MARK: - Refined Chat Header (Minimal)
    
    private var refinedChatHeader: some View {
        HStack(spacing: 16) {
            // Simple back button (iPhone only)
            if !isInSplitView {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.TextColors.primary)
                        .frame(width: 44, height: 44)
                }
            }
            
            // Clean user info (tappable)
            Button(action: {
                showUserDetails = true
            }) {
                HStack(spacing: 12) {
                    refinedUserAvatar
                    refinedUserInfo
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    private var refinedUserAvatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let avatarPath = userAvatar {
                    if avatarPath.lowercased().hasPrefix("http") {
                        AsyncImage(url: URL(string: avatarPath)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                defaultAvatar
                            }
                        }
                    } else {
                        let baseURL = APIClient.environment.baseURL
                        let cleanPath = avatarPath.hasPrefix("/") ? avatarPath : "/\(avatarPath)"
                        let fullURL = URL(string: "\(baseURL)\(cleanPath)")
                        
                        AsyncImage(url: fullURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            default:
                                defaultAvatar
                            }
                        }
                    }
                } else {
                    defaultAvatar
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Minimal online indicator
            if userOnlineStatus {
                Circle()
                    .fill(AppTheme.AccentColors.success)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(AppTheme.BackgroundColors.primary, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
        }
    }
    
    private var refinedUserInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(userName)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
                .lineLimit(1)
            
            Text(userOnlineStatus ? "Active" : lastActiveText)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(userOnlineStatus ? AppTheme.AccentColors.success : AppTheme.TextColors.tertiary)
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(AppTheme.SurfaceColors.base)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.TextColors.secondary)
            )
    }
    
    // MARK: - Refined Messages Section (Clean)
    
    private var refinedMessagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    if messageVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.AccentColors.primary))
                            .padding(.top, 32)
                    }
                    
                    if let err = messageVM.errorMessage {
                        Text(err)
                            .foregroundColor(AppTheme.AccentColors.error)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .padding(.top, 32)
                    }
                    
                    ForEach(messageVM.messages) { message in
                        RefinedMessageBubble(
                            message: message,
                            onReply: { msg in
                                replyingTo = msg
                            },
                            onReact: { msg, emoji in
                                if let messageId = msg.id {
                                    wsM.sendReaction(emoji: emoji, messageId: messageId)
                                }
                            }
                        )
                        .id(message.id)
                    }
                    
                    // Simple upload indicator
                    if isUploadingMedia {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.AccentColors.primary))
                                .scaleEffect(0.8)
                            
                            Text("Uploading...")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppTheme.TextColors.secondary)
                        }
                        .padding(12)
                        .background(AppTheme.SurfaceColors.base)
                        .cornerRadius(12)
                        .id("uploading")
                    }
                    
                    // Clean typing indicator
                    if isOtherUserTyping {
                        RefinedTypingIndicator()
                            .id("typing")
                    }
                    
                    // Bottom anchor
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onAppear {
                scrollProxy = proxy
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: messageVM.messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: isOtherUserTyping) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    // MARK: - Refined Input Bar (Simplified)
    
    private var refinedInputBar: some View {
        VStack(spacing: 0) {
            // Clean reply preview
            if let replyMsg = replyingTo {
                RefinedReplyPreview(message: replyMsg) {
                    replyingTo = nil
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if isRecordingVoice {
                // Voice recorder
                VoiceRecorderView(
                    onSend: { data, duration in
                        uploadAndSendVoiceNote(data: data, duration: duration)
                        isRecordingVoice = false
                    },
                    onCancel: {
                        isRecordingVoice = false
                    }
                )
            } else {
                // Clean message input
                HStack(spacing: 12) {
                    // Simple attachment button
                    Button(action: {
                        showMediaPicker = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(AppTheme.AccentColors.primary)
                    }
                    .disabled(isUploadingMedia)
                    
                    // Clean text field
                    TextField("Message", text: $messageText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppTheme.SurfaceColors.base)
                        .cornerRadius(20)
                    
                    // Send/Voice button
                    if messageText.isEmpty {
                        Button(action: {
                            isRecordingVoice = true
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.TextColors.primary)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.SurfaceColors.base)
                                .clipShape(Circle())
                        }
                    } else {
                        Button {
                            guard !messageText.isEmpty else { return }
                            
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            
                            wsM.sendChatMessage(
                                receiverId: userId,
                                content: messageText,
                                type: .text,
                                replyToId: replyingTo?.id
                            )
                            messageText = ""
                            replyingTo = nil
                            
                            if let proxy = scrollProxy {
                                scrollToBottom(proxy: proxy)
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(AppTheme.AccentColors.primary)
                                .clipShape(Circle())
                        }
                        .scaleEffect(isSendButtonPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isSendButtonPressed)
                        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                            isSendButtonPressed = pressing
                        }, perform: {})
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.3), value: isRecordingVoice)
    }
    
    // MARK: - Helper Methods
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
    
    // MARK: - Event Handlers (same as original)
    
    private func handleIncomingMessage() {
        guard let m = wsM.incomingMessage else { return }
        let s = m.sender?.id ?? ""
        let r = m.receiver?.id ?? ""
        let me = authVM.userId
        if (s == me && r == userId) || (s == userId && r == me) {
            Task { @MainActor in
                messageVM.append(m)
            }
        }
    }
    
    private func handleOnlineUsersChange() {
        let wasOnline = userOnlineStatus
        userOnlineStatus = wsM.isUserOnline(userId)
        
        if wasOnline && !userOnlineStatus {
            userLastActive = Date()
            wsM.updateLastActive(for: userId, date: Date())
        }
    }
    
    private func handleUserStatusUpdate() {
        if let status = wsM.userStatusUpdate, status.userId == userId {
            userOnlineStatus = status.online
            if let lastActive = status.lastActive {
                userLastActive = lastActive
            }
        }
    }
    
    private func sendMediaMessage(_ mediaItem: MediaItem) {
        // Send media message using WebSocket
        wsM.sendChatMessage(
            receiverId: userId,
            content: mediaItem.fileName,
            type: mediaItem.type
        )
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func handleReactionUpdate() {
        guard let reaction = wsM.reactionUpdate else { return }
        
        if let index = messageVM.messages.firstIndex(where: { $0.id == reaction.messageId }) {
            let message = messageVM.messages[index]
            var updatedReactions = message.reactions ?? []
            
            let newReaction = Reaction(
                id: reaction.id,
                emoji: reaction.emoji,
                userId: reaction.userId,
                user: reaction.user,
                createdAt: reaction.createdAt
            )
            updatedReactions.append(newReaction)
            
            let updatedMessage = Message(
                id: message.id,
                content: message.content,
                type: message.type,
                sender: message.sender,
                receiver: message.receiver,
                timestamp: message.timestamp,
                fileName: message.fileName,
                edited: message.edited,
                reactions: updatedReactions,
                replyTo: message.replyTo
            )
            
            Task { @MainActor in
                messageVM.updateMessage(updatedMessage)
            }
        }
    }
    
    private func handleTypingChange(oldValue: String, newValue: String) {
        typingTimer?.invalidate()
        
        if !newValue.isEmpty && oldValue != newValue {
            wsM.sendTypingIndicator(
                userId: authVM.userId,
                receiverId: userId,
                isTyping: true
            )
            
            typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak wsM, authVM, userId] _ in
                wsM?.sendTypingIndicator(
                    userId: authVM.userId,
                    receiverId: userId,
                    isTyping: false
                )
            }
        } else if newValue.isEmpty {
            wsM.sendTypingIndicator(
                userId: authVM.userId,
                receiverId: userId,
                isTyping: false
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func uploadAndSendVoiceNote(data: Data, duration: TimeInterval) {
        isUploadingMedia = true
        
        Task {
            do {
                let filename = "voice_note_\(UUID().uuidString).m4a"
                
                let response: APIResponse<String> = try await APIClient.shared.uploadMessageAttachment(
                    fileData: data,
                    filename: filename,
                    mimeType: "audio/m4a"
                )
                
                guard response.success, let fileURL = response.data else {
                    throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message])
                }
                
                wsM.sendChatMessage(
                    receiverId: userId,
                    content: fileURL,
                    type: .audio,
                    replyToId: replyingTo?.id
                )
                
                isUploadingMedia = false
                replyingTo = nil
                
            } catch {
                isUploadingMedia = false
            }
        }
    }
    
    private func resizeImage(image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = size.width / size.height
        
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxSize, height: maxSize / ratio)
        } else {
            newSize = CGSize(width: maxSize * ratio, height: maxSize)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Refined Message Bubble (Calmer)

struct RefinedMessageBubble: View {
    @EnvironmentObject var authVM: AuthViewModel
    let message: Message
    let onReply: (Message) -> Void
    let onReact: (Message, String) -> Void
    
    @State private var appeared = false
    @State private var showImageViewer = false
    @State private var showReactionPicker = false
    
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
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe {
                Spacer()
            }
            
            // Message bubble with time
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                Group {
                    switch messageType {
                    case .text:
                        refinedTextMessage
                    case .image:
                        refinedImageMessage
                    case .video:
                        refinedVideoMessage
                    case .file, .audio:
                        refinedFileMessage
                    }
                }
                .frame(maxWidth: 280, alignment: isMe ? .trailing : .leading)
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
                
                // Reactions (if any)
                if let reactions = message.reactions, !reactions.isEmpty {
                    ReactionsView(reactions: reactions, currentUserId: authVM.userId)
                }
                
                // Time
                Text(formattedTime)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.quaternary)
                    .padding(.horizontal, 4)
            }
            
            if !isMe {
                Spacer()
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : (isMe ? 30 : -30))
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showImageViewer) {
            if let url = fileURL {
                RefinedImageViewer(imageURL: url)
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
    
    // MARK: - Text Message (Clean)
    
    private var refinedTextMessage: some View {
        Text(message.content ?? "")
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(messageBubbleBackground)
            .cornerRadius(18)
    }
    
    // MARK: - Image Message (Clean)
    
    private var refinedImageMessage: some View {
        Button(action: {
            showImageViewer = true
        }) {
            if let url = fileURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
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
        .cornerRadius(18)
        .buttonStyle(PlainButtonStyle())
    }
    
    private func imagePlaceholder(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(AppTheme.TextColors.tertiary)
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.TextColors.tertiary)
        }
        .frame(width: 200, height: 200)
    }
    
    // MARK: - Video Message (Clean)
    
    @ViewBuilder
    private var refinedVideoMessage: some View {
        if let url = fileURL {
            VideoPlayer(player: AVPlayer(url: url))
                .frame(width: 200, height: 200)
                .cornerRadius(18)
        } else {
            imagePlaceholder(icon: "video", text: "Invalid URL")
        }
    }
    
    // MARK: - File Message (Clean)
    
    private var refinedFileMessage: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppTheme.AccentColors.primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(AppTheme.AccentColors.primary.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message.fileName ?? "File")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("File")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
            
            Spacer()
            
            if let url = fileURL {
                Link(destination: url) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.AccentColors.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(messageBubbleBackground)
        .cornerRadius(18)
    }
    
    // MARK: - Background (Simplified)
    
    @ViewBuilder
    private var messageBubbleBackground: some View {
        if isMe {
            // Sent messages: Simple blue
            AppTheme.AccentColors.primary
        } else {
            // Received messages: Simple gray
            AppTheme.SurfaceColors.elevated
        }
    }
}

// MARK: - Refined Typing Indicator (Minimal)

struct RefinedTypingIndicator: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Simple typing bubble
            HStack(spacing: 3) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppTheme.TextColors.tertiary)
                        .frame(width: 5, height: 5)
                        .offset(y: dotOffset(for: index))
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.SurfaceColors.base)
            .cornerRadius(16)
            
            Spacer()
        }
        .onAppear {
            animationPhase = 1
        }
    }
    
    private func dotOffset(for index: Int) -> CGFloat {
        return animationPhase == 1 ? -3 : 0
    }
}

// MARK: - Refined Reply Preview (Clean)

struct RefinedReplyPreview: View {
    let message: Message
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Simple reply line
            Rectangle()
                .fill(AppTheme.AccentColors.primary)
                .frame(width: 3)
                .cornerRadius(1.5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Replying to \(message.sender?.name ?? "Unknown")")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.AccentColors.primary)
                
                Text(message.content ?? "")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.TextColors.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
        }
        .padding(12)
        .background(AppTheme.SurfaceColors.base)
        .cornerRadius(12)
    }
}

// MARK: - Refined User Details Sheet (Minimal)

struct RefinedUserDetailsSheet: View {
    @Environment(\.dismiss) var dismiss
    let userName: String
    let userAvatar: String?
    let userId: String
    let isOnline: Bool
    let lastActive: Date?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.BackgroundColors.primary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Simple avatar section
                        VStack(spacing: 16) {
                            Group {
                                if let avatarURL = userAvatar,
                                   let url = URL(string: avatarURL),
                                   avatarURL.lowercased().hasPrefix("http") {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        default:
                                            defaultAvatar
                                        }
                                    }
                                } else {
                                    defaultAvatar
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            
                            VStack(spacing: 8) {
                                Text(userName)
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.TextColors.primary)
                                
                                Text(isOnline ? "Active now" : "Offline")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(isOnline ? AppTheme.AccentColors.success : AppTheme.TextColors.tertiary)
                            }
                        }
                        .padding(.top, 40)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("User Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.AccentColors.primary)
                }
            }
        }
    }
    
    private var defaultAvatar: some View {
        Circle()
            .fill(AppTheme.SurfaceColors.base)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(AppTheme.TextColors.secondary)
            )
    }
}

// MARK: - Refined Image Viewer (Clean)

struct RefinedImageViewer: View {
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
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                scale = 1.0
                                                lastScale = 1.0
                                            }
                                        }
                                        if scale > 4.0 {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                scale = 4.0
                                                lastScale = 4.0
                                            }
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.easeOut(duration: 0.3)) {
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
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                            Text("Failed to load image")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
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