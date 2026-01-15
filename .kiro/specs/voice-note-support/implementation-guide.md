# Voice Note Support - Implementation Guide

## Quick Start

This guide provides step-by-step instructions for implementing voice note support in RapidTalk.

## Prerequisites

✅ Backend already supports:
- `duration: Double?` field in Message model
- REST endpoint: `POST /messages/upload`
- WebSocket message handling for AUDIO type

✅ Frontend already has:
- `Message.duration` field
- `APIClient.uploadMessageAttachment()`
- `WebSocketManager.sendChatMessage()`
- Media upload flow (images/videos)

## Implementation Steps

### Step 1: Add Microphone Permission to Info.plist

Add this entry to `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>RapidTalk needs access to your microphone to record voice messages.</string>
```

### Step 2: Create AudioManager (Singleton)

Create `vynqtalk/ViewModels/AudioManager.swift`:

```swift
import Foundation
import AVFoundation

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var currentlyPlayingId: String?
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    var onPlaybackProgress: ((TimeInterval) -> Void)?
    var onPlaybackComplete: (() -> Void)?
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("  Failed to setup audio session: \(error)")
        }
    }
    
    func play(url: URL, messageId: String) {
        // Stop current playback if any
        if currentlyPlayingId != nil {
            stop()
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            currentlyPlayingId = messageId
            isPlaying = true
            
            startProgressTimer()
        } catch {
            print("  Failed to play audio: \(error)")
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    func resume() {
        audioPlayer?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingId = nil
        stopProgressTimer()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
    }
    
    func getCurrentTime() -> TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    func getDuration() -> TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    func isPlayingMessage(_ id: String) -> Bool {
        return currentlyPlayingId == id && isPlaying
    }
    
    private func startProgressTimer() {
        stopProgressTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.onPlaybackProgress?(player.currentTime)
        }
    }
    
    private func stopProgressTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
        onPlaybackComplete?()
    }
}
```

### Step 3: Create VoiceRecorder Component

Create `vynqtalk/components/VoiceRecorder.swift`:

```swift
import SwiftUI
import AVFoundation

struct VoiceRecorder: View {
    @Binding var isRecording: Bool
    let onRecordingComplete: (URL, TimeInterval) -> Void
    let onCancel: () -> Void
    
    @State private var recordingDuration: TimeInterval = 0
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingTimer: Timer?
    @State private var audioLevels: [CGFloat] = Array(repeating: 0.2, count: 20)
    @State private var recordingURL: URL?
    
    private let maxDuration: TimeInterval = 300 // 5 minutes
    
    var body: some View {
        VStack(spacing: 16) {
            // Waveform visualization
            HStack(spacing: 4) {
                ForEach(0..<audioLevels.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.AccentColors.primary)
                        .frame(width: 3, height: audioLevels[index] * 40)
                        .animation(.spring(duration: 0.3), value: audioLevels[index])
                }
            }
            .frame(height: 40)
            
            // Timer
            HStack(spacing: 8) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .opacity(isRecording ? 1 : 0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isRecording)
                
                Text(formatDuration(recordingDuration))
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            // Controls
            HStack(spacing: 20) {
                // Cancel button
                Button(action: {
                    cancelRecording()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                        Text("Cancel")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(AppTheme.AccentColors.error)
                    )
                }
                
                // Send button
                Button(action: {
                    stopRecording()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text("Send")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(AppTheme.AccentColors.success)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.AccentColors.primary.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            startRecording()
        }
    }
    
    private func startRecording() {
        checkMicrophonePermission { granted in
            guard granted else {
                onCancel()
                return
            }
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .default)
                try audioSession.setActive(true)
                
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioFilename = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
                
                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
                    AVEncoderBitRateKey: 64000
                ]
                
                audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                audioRecorder?.isMeteringEnabled = true
                audioRecorder?.record()
                
                recordingURL = audioFilename
                
                // Start timer
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.updateRecording()
                }
                
            } catch {
                print("  Failed to start recording: \(error)")
                onCancel()
            }
        }
    }
    
    private func updateRecording() {
        guard let recorder = audioRecorder else { return }
        
        recordingDuration = recorder.currentTime
        
        // Update waveform
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalizedPower = CGFloat((power + 60) / 60) // Normalize -60 to 0 dB to 0-1
        
        audioLevels.removeFirst()
        audioLevels.append(max(0.2, min(1.0, normalizedPower)))
        
        // Check max duration
        if recordingDuration >= maxDuration {
            stopRecording()
        }
    }
    
    private func stopRecording() {
        guard let recorder = audioRecorder, let url = recordingURL else {
            onCancel()
            return
        }
        
        let duration = recorder.currentTime
        recorder.stop()
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        onRecordingComplete(url, duration)
    }
    
    private func cancelRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Delete recording file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        onCancel()
    }
    
    private func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
```

### Step 4: Create VoiceNotePlayer Component

Create `vynqtalk/components/VoiceNotePlayer.swift`:

```swift
import SwiftUI
import AVFoundation

struct VoiceNotePlayer: View {
    let audioURL: URL
    let duration: Double
    let isMe: Bool
    let messageId: String
    
    @StateObject private var audioManager = AudioManager.shared
    @State private var currentTime: TimeInterval = 0
    @State private var isDragging: Bool = false
    
    private var isPlaying: Bool {
        audioManager.isPlayingMessage(messageId)
    }
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isMe ? .white.opacity(0.3) : AppTheme.AccentColors.primary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.3))
                            .frame(height: 4)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white)
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                                currentTime = duration * newProgress
                            }
                            .onEnded { value in
                                isDragging = false
                                let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                                let newTime = duration * newProgress
                                audioManager.seek(to: newTime)
                                currentTime = newTime
                            }
                    )
                }
                .frame(height: 4)
                
                // Time labels
                HStack {
                    Text(formatTime(currentTime))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Waveform icon
            Image(systemName: "waveform")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(12)
        .onAppear {
            setupPlaybackCallbacks()
        }
        .onDisappear {
            if isPlaying {
                audioManager.stop()
            }
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioManager.pause()
        } else {
            if audioManager.currentlyPlayingId == messageId {
                audioManager.resume()
            } else {
                audioManager.play(url: audioURL, messageId: messageId)
            }
        }
    }
    
    private func setupPlaybackCallbacks() {
        audioManager.onPlaybackProgress = { [weak audioManager] time in
            guard let audioManager = audioManager,
                  audioManager.currentlyPlayingId == messageId,
                  !isDragging else { return }
            
            DispatchQueue.main.async {
                currentTime = time
            }
        }
        
        audioManager.onPlaybackComplete = { [weak audioManager] in
            guard let audioManager = audioManager,
                  audioManager.currentlyPlayingId == messageId else { return }
            
            DispatchQueue.main.async {
                currentTime = 0
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
```

### Step 5: Update ChatScreen.swift

Add these state variables:

```swift
@State private var isRecordingVoice = false
@State private var recordedAudioURL: URL?
@State private var recordedAudioDuration: TimeInterval = 0
```

Update the input bar to include microphone button:

```swift
private func inputBar(spacing: ResponsiveSpacing) -> some View {
    VStack(spacing: 0) {
        // Reply preview (existing code)
        if let replyMsg = replyingTo {
            ReplyPreview(message: replyMsg) {
                replyingTo = nil
            }
            .padding(.horizontal, spacing.horizontalPadding)
            .padding(.top, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        
        // Voice recorder overlay
        if isRecordingVoice {
            VoiceRecorder(
                isRecording: $isRecordingVoice,
                onRecordingComplete: { url, duration in
                    recordedAudioURL = url
                    recordedAudioDuration = duration
                    isRecordingVoice = false
                    uploadAndSendVoiceNote(url: url, duration: duration)
                },
                onCancel: {
                    isRecordingVoice = false
                }
            )
            .padding(.horizontal, spacing.horizontalPadding)
            .padding(.vertical, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        
        HStack(spacing: 12) {
            // Attachment button (existing)
            Button(action: {
                showMediaPicker = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppTheme.AccentColors.primary)
            }
            .disabled(isUploadingMedia || isRecordingVoice)
            
            // Message text field (existing)
            messageTextField
            
            // Microphone or Send button
            if messageText.isEmpty {
                // Microphone button
                Button(action: {
                    withAnimation {
                        isRecordingVoice = true
                    }
                }) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 48, height: 48)
                        .background(micButtonGradient)
                        .shadow(
                            color: AppTheme.AccentColors.primary.opacity(0.3),
                            radius: 12,
                            y: 4
                        )
                }
                .disabled(isUploadingMedia || isRecordingVoice)
            } else {
                // Send button (existing)
                sendButton
            }
        }
        .padding(.horizontal, spacing.horizontalPadding)
        .padding(.vertical, 16)
    }
    .background(Color.black.opacity(0.3))
}

private var micButtonGradient: some View {
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
```

Add voice note upload method:

```swift
private func uploadAndSendVoiceNote(url: URL, duration: TimeInterval) {
    isUploadingMedia = true
    
    Task {
        do {
            // Read audio file
            let audioData = try Data(contentsOf: url)
            
            #if DEBUG
            print("📤 Uploading voice note: \(audioData.count) bytes, duration: \(duration)s")
            #endif
            
            // Upload to REST endpoint
            let response: APIResponse<String> = try await APIClient.shared.uploadMessageAttachment(
                fileData: audioData,
                filename: "voice_\(UUID().uuidString).m4a",
                mimeType: "audio/mp4"
            )
            
            guard response.success, let fileURL = response.data else {
                throw NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message])
            }
            
            #if DEBUG
            print("✅ Voice note uploaded: \(fileURL)")
            #endif
            
            // Send via WebSocket with duration
            wsM.sendChatMessage(
                receiverId: userId,
                content: fileURL,
                type: .audio,
                replyToId: replyingTo?.id
            )
            
            // Clean up
            try? FileManager.default.removeItem(at: url)
            
            isUploadingMedia = false
            replyingTo = nil
            
        } catch {
            #if DEBUG
            print("  Voice note upload error: \(error)")
            #endif
            isUploadingMedia = false
        }
    }
}
```

### Step 6: Update MessageBubble.swift

Update the `fileMessageView` to use VoiceNotePlayer for AUDIO type:

```swift
private var fileMessageView: some View {
    VStack(alignment: .leading, spacing: 0) {
        // Show replied message if exists and has valid content
        if hasValidReply, let repliedMsg = message.replyTo {
            RepliedMessageView(repliedMessage: repliedMsg, isMe: isMe, currentUserId: authVM.userId)
                .padding(.bottom, 8)
        }
        
        // Check if it's an audio message
        if messageType == .audio, let url = fileURL, let duration = message.duration, let messageId = message.id {
            VoiceNotePlayer(
                audioURL: url,
                duration: duration,
                isMe: isMe,
                messageId: messageId
            )
        } else {
            // Regular file display (existing code)
            HStack(spacing: 12) {
                Image(systemName: messageType == .audio ? "waveform" : "doc.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.AccentColors.primary)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(AppTheme.AccentColors.primary.opacity(0.2)))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.fileName ?? "File")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.TextColors.primary)
                        .lineLimit(1)
                    
                    Text(messageType == .audio ? "Audio" : "File")
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
            .padding(AppTheme.Spacing.m)
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
```

### Step 7: Update WSManager.swift (Optional)

The WebSocketManager already supports sending duration, but you can verify the `sendChatMessage` method includes it:

```swift
// This should already be in your WSManager.swift
func sendChatMessage(receiverId: String, content: String, type: MessageType = .text, replyToId: String? = nil) {
    let message = WebSocketSendMessage(
        receiverId: receiverId,
        content: content,
        messageType: type,
        replyToId: replyToId
    )
    // ... rest of the method
}
```

If you need to add duration to WebSocket messages, update the struct:

```swift
struct WebSocketSendMessage: Encodable {
    let type: String
    let receiverId: String
    let content: String
    let messageType: String
    let replyToId: String?
    let duration: Double?  // Add this if not present
    
    init(receiverId: String, content: String, messageType: MessageType = .text, replyToId: String? = nil, duration: Double? = nil) {
        self.type = "chat_message"
        self.receiverId = receiverId
        self.content = content
        self.messageType = messageType.rawValue
        self.replyToId = replyToId
        self.duration = duration
    }
}
```

And update the send method:

```swift
func sendChatMessage(receiverId: String, content: String, type: MessageType = .text, replyToId: String? = nil, duration: Double? = nil) {
    let message = WebSocketSendMessage(
        receiverId: receiverId,
        content: content,
        messageType: type,
        replyToId: replyToId,
        duration: duration
    )
    // ... rest of the method
}
```

Then update the ChatScreen upload method to include duration:

```swift
wsM.sendChatMessage(
    receiverId: userId,
    content: fileURL,
    type: .audio,
    replyToId: replyingTo?.id,
    duration: duration  // Add this
)
```

## Testing Checklist

- [ ] Microphone permission dialog appears on first use
- [ ] Recording starts and shows waveform animation
- [ ] Timer updates during recording
- [ ] Cancel button stops recording and discards file
- [ ] Send button uploads and sends voice note
- [ ] Voice note appears in chat with correct duration
- [ ] Play button starts playback
- [ ] Progress bar updates during playback
- [ ] Seek functionality works
- [ ] Only one voice note plays at a time
- [ ] Voice notes work with replies
- [ ] Voice notes work with reactions
- [ ] Upload progress is shown
- [ ] Error handling works (permission denied, upload failed, etc.)

## Common Issues & Solutions

### Issue: Recording doesn't start
**Solution:** Check microphone permission in Info.plist and device settings

### Issue: Audio quality is poor
**Solution:** Adjust AVAudioRecorder settings (increase bit rate or sample rate)

### Issue: File size too large
**Solution:** Lower bit rate or use more aggressive compression

### Issue: Playback doesn't work
**Solution:** Verify audio file URL is correct and file exists

### Issue: Multiple voice notes play simultaneously
**Solution:** Ensure AudioManager stops previous playback before starting new one

## Next Steps

After implementing basic voice note support:

1. Add waveform visualization during playback
2. Add playback speed control (1x, 1.5x, 2x)
3. Add voice note transcription
4. Add download voice note option
5. Optimize battery usage during recording
6. Add background recording support
7. Add voice note editing (trim, cut)

## Resources

- [AVAudioRecorder Documentation](https://developer.apple.com/documentation/avfoundation/avaudiorecorder)
- [AVAudioPlayer Documentation](https://developer.apple.com/documentation/avfoundation/avaudioplayer)
- [Audio Session Programming Guide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/)
