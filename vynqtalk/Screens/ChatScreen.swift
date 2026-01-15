//
//  ChatScreen.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI


struct ChatScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var messageVM: MessageViewModel
    @EnvironmentObject var wsM: WebSocketManager
    @Environment(\.dismiss) var dismiss
    @State private var messageText: String = ""
    @State private var isSendButtonPressed = false
    @State private var isOtherUserTyping = false // For typing indicator
    @State private var userOnlineStatus: Bool = false
    @State private var userLastActive: Date?
    @State private var showUserDetails = false
    @State private var typingTimer: Timer?
    @State private var showMediaPicker = false
    @State private var selectedMedia: MediaItem?
    @State private var isUploadingMedia = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var replyingTo: Message?
    let userId: String  // Changed from Int to String
    let userName: String
    let userAvatar: String?
    let initialLastActive: Date?
    
    init(userId: String, userName: String, userAvatar: String?, initialLastActive: Date? = nil) {
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.initialLastActive = initialLastActive
        _userLastActive = State(initialValue: initialLastActive)
    }
    
    // Format last active time
    private var lastActiveText: String {
        guard let lastActive = userLastActive else { 
            return "last seen recently" 
        }
        
        let now = Date()
        let interval = now.timeIntervalSince(lastActive)
        
        return formatTimeInterval(interval)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return "last seen just now"
        }
        
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "last seen \(minutes)m ago"
        }
        
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return "last seen \(hours)h ago"
        }
        
        let days = Int(interval / 86400)
        return "last seen \(days)d ago"
    }
    
    var body: some View {
        mainContent
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .tabBar)
            .onAppear {
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
                userDetailsSheet
            }
            .sheet(isPresented: $showMediaPicker) {
                mediaPickerSheet
            }
            .onChange(of: selectedMedia) { _, newMedia in
                handleMediaSelection(newMedia)
            }
            .onChange(of: wsM.reactionUpdate?.id) { _, _ in
                handleReactionUpdate()
            }
    }
    
    private var mainContent: some View {
        GeometryReader { geometry in
            let spacing = ResponsiveSpacing(screenWidth: geometry.size.width)
            
            ZStack {
                AnimatedGradientBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    chatHeader(spacing: spacing)
                    messagesSection(spacing: spacing)
                    inputBar(spacing: spacing)
                }
                .frame(maxWidth: spacing.contentMaxWidth)
                .frame(width: geometry.size.width)
            }
        }
    }
    
    // MARK: - Event Handlers
    
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
    
    private func handleMediaSelection(_ newMedia: MediaItem?) {
        if let media = newMedia {
            uploadAndSendMedia(media)
        }
    }
    
    private func handleReactionUpdate() {
        guard let reaction = wsM.reactionUpdate else { return }
        
        // Find the message and update its reactions
        if let message = messageVM.messages.first(where: { $0.id == reaction.messageId }) {
            var updatedReactions = message.reactions ?? []
            
            // Add the new reaction
            let newReaction = Reaction(emoji: reaction.emoji, userId: reaction.userId)
            updatedReactions.append(newReaction)
            
            // Update the message with new reactions
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
    
    private var userDetailsSheet: some View {
        UserDetailsSheet(
            userName: userName,
            userAvatar: userAvatar,
            userId: userId,
            isOnline: userOnlineStatus,
            lastActive: userLastActive
        )
    }
    
    private var mediaPickerSheet: some View {
        MediaPicker(selectedMedia: $selectedMedia)
    }
    
    // MARK: - Header
    
    private func chatHeader(spacing: ResponsiveSpacing) -> some View {
        HStack(spacing: 12) {
            backButton
            
            // Tappable user info section
            Button(action: {
                showUserDetails = true
            }) {
                HStack(spacing: 12) {
                    userAvatarView
                    userInfoView
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            moreOptionsButton
        }
        .padding(.horizontal, spacing.horizontalPadding)
        .padding(.vertical, 12)
        .background(headerBackground)
    }
    
    private var backButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.TextColors.primary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.white.opacity(0.1)))
        }
    }
    
    private var userAvatarView: some View {
        Group {
            if let avatarPath = userAvatar {
                // Check if it's already a full URL
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
                    // Construct full URL from relative path
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
        .frame(width: 42, height: 42)
        .clipShape(Circle())
        .overlay(avatarBorder)
        .overlay(onlineIndicator)
    }
    
    private var avatarBorder: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        AppTheme.AccentColors.primary,
                        AppTheme.AccentColors.secondary
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
    }
    
    private var onlineIndicator: some View {
        Circle()
            .fill(userOnlineStatus ? AppTheme.AccentColors.success : .gray)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(Color.black, lineWidth: 2))
            .offset(x: 15, y: 15)
    }
    
    private var userInfoView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(userName)
                .foregroundColor(AppTheme.TextColors.primary)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .lineLimit(1)
            
            Text(userOnlineStatus ? "Active now" : lastActiveText)
                .foregroundColor(userOnlineStatus ? AppTheme.AccentColors.success : AppTheme.TextColors.tertiary)
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
    }
    
    private var moreOptionsButton: some View {
        Button(action: {}) {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.TextColors.primary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.white.opacity(0.1)))
        }
    }
    
    private var headerBackground: some View {
        Color.black.opacity(0.4)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.05), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
    }
    
    // MARK: - Messages Section
    
    private func messagesSection(spacing: ResponsiveSpacing) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if messageVM.isLoading {
                        LoadingView(style: .spinner)
                            .padding(.top, 32)
                    }
                    if let err = messageVM.errorMessage {
                        Text(err)
                            .foregroundColor(AppTheme.AccentColors.error)
                            .font(AppTheme.Typography.body)
                            .padding(.top, 32)
                    }
                    ForEach(messageVM.messages) { message in
                        MessageBubble(
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
                    
                    // Show uploading indicator
                    if isUploadingMedia {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(AppTheme.AccentColors.primary)
                            Text("Uploading...")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.TextColors.secondary)
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.l)
                                .fill(AppTheme.SurfaceColors.surface)
                        )
                        .id("uploading")
                    }
                    
                    if isOtherUserTyping {
                        TypingIndicator()
                            .id("typing")
                    }
                    
                    // Invisible anchor at the bottom
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, spacing.horizontalPadding)
                .padding(.vertical, 20)
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
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
    
    // MARK: - Input Bar
    
    private func inputBar(spacing: ResponsiveSpacing) -> some View {
        VStack(spacing: 0) {
            // Reply preview
            if let replyMsg = replyingTo {
                ReplyPreview(message: replyMsg) {
                    replyingTo = nil
                }
                .padding(.horizontal, spacing.horizontalPadding)
                .padding(.top, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            HStack(spacing: 12) {
                // Attachment button
                Button(action: {
                    showMediaPicker = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppTheme.AccentColors.primary)
                }
                .disabled(isUploadingMedia)
                
                messageTextField
                sendButton
            }
            .padding(.horizontal, spacing.horizontalPadding)
            .padding(.vertical, 16)
        }
        .background(Color.black.opacity(0.3))
    }
    
    private var messageTextField: some View {
        TextField("Message", text: $messageText)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.SurfaceColors.surface)
            )
            .foregroundColor(AppTheme.TextColors.primary)
            .font(.system(size: 16, weight: .medium, design: .rounded))
    }
    
    private var sendButton: some View {
        Button {
            guard !messageText.isEmpty else { return }
            wsM.sendChatMessage(
                receiverId: userId,
                content: messageText,
                type: .text,
                replyToId: replyingTo?.id
            )
            messageText = ""
            replyingTo = nil
            
            // Scroll to bottom after sending
            if let proxy = scrollProxy {
                scrollToBottom(proxy: proxy)
            }
        } label: {
            Image(systemName: "paperplane.fill")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 48, height: 48)
                .background(sendButtonGradient)
                .shadow(
                    color: AppTheme.AccentColors.primary.opacity(0.3),
                    radius: 12,
                    y: 4
                )
        }
        .scaleEffect(isSendButtonPressed ? 0.92 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(AppTheme.AnimationCurves.buttonPress) {
                isSendButtonPressed = pressing
            }
        }, perform: {})
    }
    
    private var sendButtonGradient: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        AppTheme.AccentColors.primary,
                        Color(red: 0.45, green: 0.35, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    // MARK: - Default Avatar
    
    private var defaultAvatar: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.AccentColors.primary,
                    AppTheme.AccentColors.secondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "person.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Typing Indicator Logic
    
    private func handleTypingChange(oldValue: String, newValue: String) {
        // Cancel existing timer
        typingTimer?.invalidate()
        
        // If user is typing (text is not empty and changed)
        if !newValue.isEmpty && oldValue != newValue {
            // Send typing = true
            wsM.sendTypingIndicator(
                userId: authVM.userId,
                receiverId: userId,
                isTyping: true
            )
            
            // Set timer to send typing = false after 2 seconds of inactivity
            typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak wsM, authVM, userId] _ in
                wsM?.sendTypingIndicator(
                    userId: authVM.userId,
                    receiverId: userId,
                    isTyping: false
                )
            }
        } else if newValue.isEmpty {
            // If text is cleared, immediately send typing = false
            wsM.sendTypingIndicator(
                userId: authVM.userId,
                receiverId: userId,
                isTyping: false
            )
        }
    }
    
    // MARK: - Media Upload
    
    private func uploadAndSendMedia(_ media: MediaItem) {
        isUploadingMedia = true
        
        Task {
            do {
                // Compress if image
                var uploadData = media.data
                var filename = media.filename
                
                if media.type == .image, let image = media.thumbnail {
                    // Resize and compress image
                    let resizedImage = resizeImage(image: image, maxSize: 1200)
                    if let compressedData = resizedImage.jpegData(compressionQuality: 0.7) {
                        uploadData = compressedData
                        filename = "image_\(UUID().uuidString).jpg"
                    }
                }
                
                #if DEBUG
                print("📤 Uploading \(media.type): \(uploadData.count) bytes")
                #endif
                
                // Step 1: Upload file to REST endpoint
                let response: APIResponse<String> = try await APIClient.shared.uploadMessageAttachment(
                    fileData: uploadData,
                    filename: filename,
                    mimeType: media.mimeType
                )
                
                guard response.success, let fileURL = response.data else {
                    throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message])
                }
                
                #if DEBUG
                print("✅ File uploaded: \(fileURL)")
                #endif
                
                // Step 2: Send message via WebSocket with file URL
                wsM.sendChatMessage(
                    receiverId: userId,
                    content: fileURL,
                    type: media.messageType,
                    replyToId: replyingTo?.id
                )
                
                isUploadingMedia = false
                selectedMedia = nil
                replyingTo = nil
                
            } catch {
                #if DEBUG
                print("  Media upload error: \(error)")
                #endif
                isUploadingMedia = false
                selectedMedia = nil
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


// MARK: - User Details Sheet

struct UserDetailsSheet: View {
    @Environment(\.dismiss) var dismiss
    let userName: String
    let userAvatar: String?
    let userId: String
    let isOnline: Bool
    let lastActive: Date?
    
    private var lastActiveText: String {
        guard let lastActive = lastActive else { return "Recently" }
        
        let now = Date()
        let interval = now.timeIntervalSince(lastActive)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Avatar Section
                        VStack(spacing: 20) {
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
                                } else if let avatarPath = userAvatar {
                                    // Handle relative path
                                    let baseURL = APIClient.environment.baseURL
                                    let cleanPath = avatarPath.hasPrefix("/") ? avatarPath : "/\(avatarPath)"
                                    let fullURL = URL(string: "\(baseURL)\(cleanPath)")
                                    
                                    AsyncImage(url: fullURL) { phase in
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
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                AppTheme.AccentColors.primary,
                                                AppTheme.AccentColors.secondary
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .overlay(
                                Circle()
                                    .fill(isOnline ? AppTheme.AccentColors.success : .gray)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 3)
                                    )
                                    .offset(x: 45, y: 45)
                            )
                            
                            VStack(spacing: 8) {
                                Text(userName)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(isOnline ? AppTheme.AccentColors.success : .gray)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(isOnline ? "Active now" : "Last seen \(lastActiveText)")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(.top, 40)
                        
                        // Info Cards
                        VStack(spacing: 16) {
                            InfoCard(
                                icon: "person.circle.fill",
                                title: "User ID",
                                value: userId,
                                color: AppTheme.AccentColors.primary
                            )
                            
                            InfoCard(
                                icon: "clock.fill",
                                title: "Status",
                                value: isOnline ? "Online" : "Offline",
                                color: isOnline ? AppTheme.AccentColors.success : .gray
                            )
                            
                            if !isOnline, let lastActive = lastActive {
                                InfoCard(
                                    icon: "calendar",
                                    title: "Last Active",
                                    value: formatFullDate(lastActive),
                                    color: AppTheme.AccentColors.secondary
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
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
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
        }
    }
    
    private var defaultAvatar: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.AccentColors.primary,
                    AppTheme.AccentColors.secondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "person.fill")
                .font(.system(size: 50, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
