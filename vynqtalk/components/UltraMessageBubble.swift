//
//  UltraMessageBubble.swift
//  vynqtalk
//
//  Ultra-Refined Message Bubble - Perfect Apple Quality
//  In-app media playback, zero downloads
//

import SwiftUI
import AVKit
import AVFoundation

struct UltraMessageBubble: View {
    @EnvironmentObject var authVM: AuthViewModel
    let message: Message
    let onReply: ((Message) -> Void)?
    let onReact: ((Message, String) -> Void)?
    
    @State private var appeared = false
    @State private var showImageViewer = false
    @State private var showReactionPicker = false
    
    var isMe: Bool {
        message.sender?.id == authVM.userId
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
    
    init(message: Message, onReply: ((Message) -> Void)? = nil, onReact: ((Message, String) -> Void)? = nil) {
        self.message = message
        self.onReply = onReply
        self.onReact = onReact
    }
    
    var body: some View {
        HStack {
            if isMe { Spacer() }
            
            VStack(alignment: isMe ? .trailing : .leading, spacing: UltraTheme.Layout.xs) {
                // Perfect message content
                messageContent
                
                // Perfect timestamp
                if let timestamp = message.timestamp {
                    Text(formatTime(timestamp))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(UltraTheme.Text.quaternary)
                        .padding(.horizontal, UltraTheme.Layout.s)
                }
                
                // Perfect reactions
                if let reactions = message.reactions, !reactions.isEmpty {
                    UltraReactionsView(reactions: reactions, currentUserId: authVM.userId)
                }
            }
            
            if !isMe { Spacer() }
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : (isMe ? 20 : -20))
        .onAppear {
            withAnimation(UltraTheme.Motion.gentle.delay(0.1)) {
                appeared = true
            }
        }
        .contextMenu {
            if let onReply = onReply {
                Button(action: { onReply(message) }) {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }
            }
            
            if let onReact = onReact {
                Button(action: { showReactionPicker = true }) {
                    Label("React", systemImage: "face.smiling")
                }
            }
        }
        .sheet(isPresented: $showImageViewer) {
            if let url = fileURL {
                UltraImageViewer(imageURL: url)
            }
        }
        .sheet(isPresented: $showReactionPicker) {
            UltraReactionPicker { emoji in
                onReact?(message, emoji)
            }
        }
    }
    
    // MARK: - Message Content
    
    @ViewBuilder
    private var messageContent: some View {
        switch messageType {
        case .text:
            ultraTextMessage
        case .image:
            ultraImageMessage
        case .video:
            ultraVideoMessage
        case .audio:
            ultraAudioMessage
        case .file:
            ultraFileMessage
        }
    }
    
    // MARK: - Text Message
    
    private var ultraTextMessage: some View {
        Text(message.content ?? "")
            .font(UltraTheme.Typography.body)
            .foregroundColor(.white)
            .padding(.horizontal, UltraTheme.Layout.m)
            .padding(.vertical, UltraTheme.Layout.s)
            .background(
                Capsule()
                    .fill(isMe ? UltraTheme.Accent.primary : UltraTheme.Glass.elevated)
            )
    }
    
    // MARK: - Image Message
    
    private var ultraImageMessage: some View {
        Button(action: { showImageViewer = true }) {
            AsyncImage(url: fileURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipped()
                case .failure:
                    ultraMediaPlaceholder(icon: "photo", text: "Failed to load")
                case .empty:
                    ultraMediaPlaceholder(icon: "photo", text: "Loading...")
                @unknown default:
                    ultraMediaPlaceholder(icon: "photo", text: "Unknown")
                }
            }
            .cornerRadius(UltraTheme.Layout.radius)
            .ultraShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Video Message (In-App Playback)
    
    private var ultraVideoMessage: some View {
        Group {
            if let url = fileURL {
                UltraVideoPlayer(url: url)
                    .frame(width: 200, height: 200)
                    .cornerRadius(UltraTheme.Layout.radius)
                    .ultraShadow()
            } else {
                ultraMediaPlaceholder(icon: "video", text: "Invalid URL")
            }
        }
    }
    
    // MARK: - Audio Message (In-App Playback)
    
    private var ultraAudioMessage: some View {
        Group {
            if let url = fileURL {
                UltraAudioPlayer(url: url, isMe: isMe)
            } else {
                ultraMediaPlaceholder(icon: "waveform", text: "Invalid audio")
            }
        }
    }
    
    // MARK: - File Message (In-App Preview)
    
    private var ultraFileMessage: some View {
        Group {
            if let url = fileURL {
                UltraFilePreview(url: url, fileName: message.fileName ?? "File")
            } else {
                ultraMediaPlaceholder(icon: "doc", text: "Invalid file")
            }
        }
    }
    
    // MARK: - Media Placeholder
    
    private func ultraMediaPlaceholder(icon: String, text: String) -> some View {
        VStack(spacing: UltraTheme.Layout.s) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(UltraTheme.Text.tertiary)
            
            Text(text)
                .font(UltraTheme.Typography.caption)
                .foregroundColor(UltraTheme.Text.tertiary)
        }
        .frame(width: 120, height: 80)
        .background(UltraTheme.Glass.surface)
        .cornerRadius(UltraTheme.Layout.radius)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Ultra Video Player (In-App)

struct UltraVideoPlayer: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onTapGesture {
                        togglePlayback()
                    }
            } else {
                Rectangle()
                    .fill(UltraTheme.Glass.surface)
                    .overlay(
                        VStack(spacing: UltraTheme.Layout.s) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: UltraTheme.Accent.primary))
                            
                            Text("Loading video...")
                                .font(UltraTheme.Typography.caption)
                                .foregroundColor(UltraTheme.Text.tertiary)
                        }
                    )
            }
            
            // Play/Pause overlay
            if let player = player {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: togglePlayback) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                        .blur(radius: 10)
                                )
                        }
                        .padding(UltraTheme.Layout.s)
                    }
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        player = AVPlayer(url: url)
        
        // Monitor playback state
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            isPlaying = false
            player?.seek(to: .zero)
        }
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Ultra Audio Player (In-App)

struct UltraAudioPlayer: View {
    let url: URL
    let isMe: Bool
    
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: UltraTheme.Layout.m) {
            // Play/Pause button
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(UltraTheme.Accent.primary)
            }
            
            VStack(alignment: .leading, spacing: UltraTheme.Layout.xs) {
                // Waveform visualization
                HStack(spacing: 2) {
                    ForEach(0..<15) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(UltraTheme.Accent.primary.opacity(currentTime > 0 && index < Int(currentTime / duration * 15) ? 1.0 : 0.3))
                            .frame(width: 3, height: CGFloat.random(in: 8...20))
                            .animation(.easeInOut(duration: 0.1), value: currentTime)
                    }
                }
                
                // Duration
                HStack {
                    Text(formatDuration(currentTime))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(UltraTheme.Text.secondary)
                    
                    Spacer()
                    
                    Text(formatDuration(duration))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(UltraTheme.Text.tertiary)
                }
            }
        }
        .padding(UltraTheme.Layout.m)
        .background(
            Capsule()
                .fill(isMe ? UltraTheme.Accent.primary.opacity(0.1) : UltraTheme.Glass.elevated)
        )
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func setupAudioPlayer() {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
        } catch {
            print("Failed to setup audio player: \(error)")
        }
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            timer?.invalidate()
        } else {
            player.play()
            startTimer()
        }
        
        isPlaying.toggle()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func stopPlayback() {
        player?.stop()
        timer?.invalidate()
        isPlaying = false
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            currentTime = player?.currentTime ?? 0
            
            if currentTime >= duration {
                stopPlayback()
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Ultra File Preview (In-App)

struct UltraFilePreview: View {
    let url: URL
    let fileName: String
    
    @State private var showQuickLook = false
    
    var body: some View {
        Button(action: { showQuickLook = true }) {
            HStack(spacing: UltraTheme.Layout.m) {
                // File icon
                Image(systemName: fileIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(UltraTheme.Accent.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(UltraTheme.Accent.primary.opacity(0.1))
                    )
                
                // File info
                VStack(alignment: .leading, spacing: UltraTheme.Layout.xs) {
                    Text(fileName)
                        .font(UltraTheme.Typography.body)
                        .foregroundColor(UltraTheme.Text.primary)
                        .lineLimit(1)
                    
                    Text(fileExtension.uppercased())
                        .font(UltraTheme.Typography.caption)
                        .foregroundColor(UltraTheme.Text.tertiary)
                }
                
                Spacer()
                
                // Preview indicator
                Image(systemName: "eye")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(UltraTheme.Text.tertiary)
            }
            .padding(UltraTheme.Layout.m)
            .background(UltraTheme.Glass.surface)
            .cornerRadius(UltraTheme.Layout.radius)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showQuickLook) {
            UltraQuickLookView(url: url)
        }
    }
    
    private var fileIcon: String {
        let ext = fileExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext"
        case "doc", "docx": return "doc.text"
        case "xls", "xlsx": return "tablecells"
        case "ppt", "pptx": return "rectangle.3.group.bubble.left"
        case "zip", "rar": return "archivebox"
        case "txt": return "doc.plaintext"
        default: return "doc"
        }
    }
    
    private var fileExtension: String {
        url.pathExtension.isEmpty ? "file" : url.pathExtension
    }
}

// MARK: - Ultra Quick Look View

struct UltraQuickLookView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let quickLookController = QLPreviewController()
        quickLookController.dataSource = context.coordinator
        quickLookController.delegate = context.coordinator
        
        let navController = UINavigationController(rootViewController: quickLookController)
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let url: URL
        
        init(url: URL) {
            self.url = url
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}

// MARK: - Ultra Image Viewer

struct UltraImageViewer: View {
    @Environment(\.dismiss) var dismiss
    let imageURL: URL
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
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
                            .offset(offset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = lastScale * value
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                            if scale < 1.0 {
                                                withAnimation(UltraTheme.Motion.spring) {
                                                    scale = 1.0
                                                    lastScale = 1.0
                                                    offset = .zero
                                                    lastOffset = .zero
                                                }
                                            }
                                            if scale > 4.0 {
                                                withAnimation(UltraTheme.Motion.spring) {
                                                    scale = 4.0
                                                    lastScale = 4.0
                                                }
                                            }
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        }
                                )
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(UltraTheme.Motion.spring) {
                                    if scale > 1.0 {
                                        scale = 1.0
                                        lastScale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    } else {
                                        scale = 2.0
                                        lastScale = 2.0
                                    }
                                }
                            }
                    case .failure:
                        VStack(spacing: UltraTheme.Layout.l) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.white)
                            Text("Failed to load image")
                                .font(UltraTheme.Typography.body)
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
                    .font(UltraTheme.Typography.body)
                }
            }
        }
    }
}

// MARK: - Ultra Reactions View

struct UltraReactionsView: View {
    let reactions: [Reaction]
    let currentUserId: String
    
    var body: some View {
        HStack(spacing: UltraTheme.Layout.xs) {
            ForEach(groupedReactions, id: \.emoji) { group in
                HStack(spacing: UltraTheme.Layout.xs) {
                    Text(group.emoji)
                        .font(.system(size: 12))
                    
                    if group.count > 1 {
                        Text("\(group.count)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(UltraTheme.Text.tertiary)
                    }
                }
                .padding(.horizontal, UltraTheme.Layout.s)
                .padding(.vertical, UltraTheme.Layout.xs)
                .background(
                    Capsule()
                        .fill(group.hasCurrentUser ? UltraTheme.Accent.primary.opacity(0.2) : UltraTheme.Glass.surface)
                )
            }
        }
    }
    
    private var groupedReactions: [ReactionGroup] {
        let grouped = Dictionary(grouping: reactions) { $0.emoji }
        return grouped.map { emoji, reactions in
            ReactionGroup(
                emoji: emoji,
                count: reactions.count,
                hasCurrentUser: reactions.contains { $0.userId == currentUserId }
            )
        }
    }
    
    private struct ReactionGroup {
        let emoji: String
        let count: Int
        let hasCurrentUser: Bool
    }
}

// MARK: - Ultra Reaction Picker

struct UltraReactionPicker: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    private let emojis = ["❤️", "😂", "😮", "😢", "😡", "👍", "👎", "🔥", "🎉", "💯"]
    
    var body: some View {
        VStack(spacing: UltraTheme.Layout.l) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(UltraTheme.Text.quaternary)
                .frame(width: 40, height: 4)
                .padding(.top, UltraTheme.Layout.s)
            
            // Title
            Text("Add Reaction")
                .font(UltraTheme.Typography.title)
                .foregroundColor(UltraTheme.Text.primary)
            
            // Emoji grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: UltraTheme.Layout.m) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        onSelect(emoji)
                        dismiss()
                    }) {
                        Text(emoji)
                            .font(.system(size: 32))
                            .frame(width: 50, height: 50)
                            .background(UltraTheme.Glass.surface)
                            .cornerRadius(UltraTheme.Layout.radiusSmall)
                    }
                    .buttonStyle(UltraButtonStyle())
                }
            }
            
            Spacer()
        }
        .padding(UltraTheme.Layout.l)
        .background(UltraTheme.Backgrounds.surface)
    }
}

import QuickLook