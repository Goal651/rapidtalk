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
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // Initialize online status from WebSocket
            userOnlineStatus = wsM.isUserOnline(userId)
        }
        .task {
            await messageVM.loadConversation(meId: authVM.userId, otherUserId: userId)
        }
        .onChange(of: wsM.incomingMessage?.id) { _, _ in
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
        .onChange(of: wsM.onlineUserIds) { _, _ in
            // Update online status when the online users list changes
            userOnlineStatus = wsM.isUserOnline(userId)
        }
        .onChange(of: wsM.userStatusUpdate?.userId) { _, _ in
            // Update when individual user status changes
            if let status = wsM.userStatusUpdate, status.userId == userId {
                userOnlineStatus = status.online
                if let lastActive = status.lastActive {
                    userLastActive = lastActive
                }
            }
        }
        .onChange(of: wsM.typingUsers[userId]) { _, isTyping in
            // Update typing indicator when the other user's typing status changes
            isOtherUserTyping = isTyping == true
        }
        .onChange(of: messageText) { oldValue, newValue in
            // Send typing indicator when user types
            handleTypingChange(oldValue: oldValue, newValue: newValue)
        }
        .sheet(isPresented: $showUserDetails) {
            UserDetailsSheet(
                userName: userName,
                userAvatar: userAvatar,
                userId: userId,
                isOnline: userOnlineStatus,
                lastActive: userLastActive
            )
        }
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
            if let avatarString = userAvatar,
               let url = URL(string: avatarString),
               avatarString.lowercased().hasPrefix("http") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        defaultAvatar
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
                    MessageBubble(message: message)
                }
                
                if isOtherUserTyping {
                    TypingIndicator()
                }
            }
            .padding(.horizontal, spacing.horizontalPadding)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Input Bar
    
    private func inputBar(spacing: ResponsiveSpacing) -> some View {
        HStack(spacing: 12) {
            messageTextField
            sendButton
        }
        .padding(.horizontal, spacing.horizontalPadding)
        .padding(.vertical, 16)
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
                type: .text
            )
            messageText = ""
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
                                if let avatarString = userAvatar,
                                   let url = URL(string: avatarString),
                                   avatarString.lowercased().hasPrefix("http") {
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
