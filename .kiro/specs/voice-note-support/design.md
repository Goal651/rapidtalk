# Voice Note Support - Design Document

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        ChatScreen                            │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │ VoiceRecorder  │  │ MediaPicker  │  │ Input Bar       │ │
│  │ Component      │  │              │  │ [+][Text][🎤]   │ │
│  └────────────────┘  └──────────────┘  └─────────────────┘ │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Message List (ScrollView)                │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │ MessageBubble (AUDIO type)                     │  │  │
│  │  │  ┌──────────────────────────────────────────┐  │  │  │
│  │  │  │      VoiceNotePlayer Component           │  │  │  │
│  │  │  │  [▶] ━━━━━━━━━━━━━━━━━ 0:45 / 1:23      │  │  │  │
│  │  │  └──────────────────────────────────────────┘  │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────────┐
        │      Audio Processing Layer           │
        │  ┌─────────────┐  ┌─────────────────┐ │
        │  │AVAudioRec.. │  │ AVAudioPlayer   │ │
        │  └─────────────┘  └─────────────────┘ │
        └───────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────────┐
        │         Network Layer                 │
        │  ┌─────────────┐  ┌─────────────────┐ │
        │  │ APIClient   │  │ WSManager       │ │
        │  │ (REST)      │  │ (WebSocket)     │ │
        │  └─────────────┘  └─────────────────┘ │
        └───────────────────────────────────────┘
```

## Component Specifications

### 1. VoiceRecorder Component

**Purpose:** Handle voice recording with visual feedback

**State:**
```swift
@State private var isRecording: Bool = false
@State private var recordingDuration: TimeInterval = 0
@State private var audioRecorder: AVAudioRecorder?
@State private var recordingTimer: Timer?
@State private var audioLevels: [CGFloat] = []
@State private var recordingURL: URL?
```

**Methods:**
```swift
func startRecording()
func stopRecording()
func cancelRecording()
func updateAudioLevels()
func getRecordingDuration() -> TimeInterval
func compressAudio(url: URL) -> Data?
```

**UI Elements:**
- Waveform visualization (animated bars)
- Timer display (MM:SS format)
- Cancel button (red, left side)
- Send button (green, right side)
- Recording indicator (pulsing red dot)

**Audio Settings:**
```swift
let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
    AVSampleRateKey: 44100.0,
    AVNumberOfChannelsKey: 1,
    AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
    AVEncoderBitRateKey: 64000
]
```

### 2. VoiceNotePlayer Component

**Purpose:** Play voice notes with progress tracking

**State:**
```swift
@State private var isPlaying: Bool = false
@State private var currentTime: TimeInterval = 0
@State private var duration: TimeInterval
@State private var audioPlayer: AVAudioPlayer?
@State private var playbackTimer: Timer?
@State private var isDragging: Bool = false
```

**Props:**
```swift
let audioURL: URL
let duration: Double
let isMe: Bool
```

**Methods:**
```swift
func play()
func pause()
func seek(to time: TimeInterval)
func updateProgress()
func formatTime(_ time: TimeInterval) -> String
```

**UI Elements:**
- Play/pause button (circle, 40x40)
- Progress bar (seekable)
- Current time label
- Total duration label
- Waveform icon

### 3. VoiceNoteButton Component

**Purpose:** Microphone button with recording gesture

**State:**
```swift
@State private var isPressed: Bool = false
@State private var dragOffset: CGFloat = 0
@GestureState private var isLongPressing: Bool = false
```

**Gestures:**
- Long press to start recording
- Drag left to cancel (threshold: -100 points)
- Release to send

**UI Elements:**
- Microphone icon
- Circular background (gradient)
- Slide-to-cancel indicator
- Haptic feedback

## Data Flow

### Recording Flow
```
User taps mic button
    ↓
Check microphone permission
    ↓
Start AVAudioRecorder
    ↓
Update UI (show waveform, timer)
    ↓
User releases button / taps send
    ↓
Stop recording
    ↓
Calculate duration
    ↓
Compress audio
    ↓
Upload to REST endpoint
    ↓
Send WebSocket message with duration
    ↓
Clear recording state
```

### Playback Flow
```
User taps play button
    ↓
Stop any currently playing audio
    ↓
Load audio from URL
    ↓
Start AVAudioPlayer
    ↓
Update play button to pause
    ↓
Start progress timer
    ↓
Update progress bar every 0.1s
    ↓
On completion: reset to play button
```

### Upload Flow
```
Recording completed
    ↓
Get audio file URL
    ↓
Calculate duration: audioRecorder.currentTime
    ↓
Read file data
    ↓
Compress if needed (target: <1MB)
    ↓
APIClient.uploadMessageAttachment()
    ↓
Receive file path: "/uploads/UUID-audio.m4a"
    ↓
WSManager.sendChatMessage(
    type: .audio,
    content: filePath,
    duration: duration
)
```

## File Structure

```
vynqtalk/
├── components/
│   ├── VoiceRecorder.swift          [NEW]
│   ├── VoiceNotePlayer.swift        [NEW]
│   ├── VoiceNoteButton.swift        [NEW]
│   ├── WaveformView.swift           [NEW]
│   └── MessageBubble.swift          [MODIFY]
├── Screens/
│   └── ChatScreen.swift             [MODIFY]
├── ViewModels/
│   ├── WSManager.swift              [MODIFY]
│   └── AudioManager.swift           [NEW]
├── models/
│   └── Message.swift                [DONE ✅]
└── services/
    └── client.swift                 [DONE ✅]
```

## State Management

### ChatScreen State
```swift
@State private var isRecordingVoice: Bool = false
@State private var recordedAudioURL: URL?
@State private var recordedAudioDuration: TimeInterval = 0
@State private var isUploadingAudio: Bool = false
@State private var currentlyPlayingMessageId: String?
```

### AudioManager (Singleton)
```swift
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published var currentlyPlayingId: String?
    @Published var isPlaying: Bool = false
    
    private var audioPlayer: AVAudioPlayer?
    
    func play(url: URL, messageId: String)
    func pause()
    func stop()
    func isPlayingMessage(_ id: String) -> Bool
}
```

## UI/UX Specifications

### Colors
- Recording indicator: `.red`
- Send button: `AppTheme.AccentColors.success`
- Cancel button: `AppTheme.AccentColors.error`
- Waveform bars: `AppTheme.AccentColors.primary`
- Progress bar (filled): `AppTheme.AccentColors.primary`
- Progress bar (unfilled): `.white.opacity(0.3)`

### Animations
- Recording pulse: 1.5s infinite ease-in-out
- Waveform bars: 0.3s spring animation
- Button press: 0.2s ease-out scale(0.92)
- Progress bar: 0.1s linear

### Typography
- Timer: `.system(size: 16, weight: .semibold, design: .monospaced)`
- Duration: `.system(size: 14, weight: .medium, design: .monospaced)`

### Spacing
- Recording UI padding: 16px
- Player controls spacing: 12px
- Waveform bar spacing: 4px
- Button size: 48x48

## Permission Handling

### Info.plist Entry
```xml
<key>NSMicrophoneUsageDescription</key>
<string>RapidTalk needs access to your microphone to record voice messages.</string>
```

### Permission Check Flow
```swift
func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
    switch AVAudioSession.sharedInstance().recordPermission {
    case .granted:
        completion(true)
    case .denied:
        showPermissionDeniedAlert()
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
```

## Error Handling

### Recording Errors
- Microphone permission denied → Show alert with settings link
- Recording failed → Show toast: "Failed to record audio"
- Maximum duration reached → Auto-stop and show message
- Storage full → Show alert: "Not enough storage space"

### Upload Errors
- Network error → Show retry button
- File too large → Compress more aggressively
- Server error → Show error message with retry

### Playback Errors
- File not found → Show "Audio unavailable"
- Corrupted file → Show "Cannot play audio"
- Network error → Show "Failed to load audio"

## Performance Considerations

### Memory Management
- Release AVAudioRecorder after recording completes
- Release AVAudioPlayer when not in use
- Limit waveform data points to 50 max
- Clear audio file cache periodically

### Battery Optimization
- Stop recording timer when not recording
- Pause playback when app goes to background
- Use efficient audio format (AAC)
- Minimize UI updates during recording

### Network Optimization
- Compress audio before upload
- Show upload progress
- Support upload retry
- Cache downloaded audio files

## Accessibility

### VoiceOver Support
```swift
.accessibilityLabel("Record voice message")
.accessibilityHint("Long press to record, release to send")
.accessibilityAddTraits(.isButton)
```

### Voice Note Message
```swift
.accessibilityLabel("Voice message, \(formatDuration(duration))")
.accessibilityHint("Double tap to play")
```

### Player Controls
```swift
.accessibilityLabel(isPlaying ? "Pause" : "Play")
.accessibilityValue("\(currentTime) of \(duration)")
```

## Testing Strategy

### Unit Tests
- Audio compression quality
- Duration calculation accuracy
- Time formatting functions
- Permission state handling

### Integration Tests
- Record → Upload → Send flow
- Download → Play flow
- Multiple voice notes in conversation
- Switching between playing voice notes

### UI Tests
- Recording gesture (long press, slide to cancel)
- Playback controls (play, pause, seek)
- Permission dialogs
- Error states

### Manual Tests
- Test on iPhone SE (small screen)
- Test on iPhone 15 Pro Max (large screen)
- Test with poor network
- Test with no network
- Test background/foreground transitions
- Test with other audio playing (music, etc.)

## Migration Path

### Phase 1: Basic Recording
1. Add VoiceRecorder component
2. Add microphone button to ChatScreen
3. Implement recording with timer
4. Test recording quality

### Phase 2: Upload Integration
1. Calculate duration after recording
2. Compress audio file
3. Upload via REST API
4. Send WebSocket message
5. Test end-to-end flow

### Phase 3: Playback
1. Add VoiceNotePlayer component
2. Update MessageBubble for AUDIO type
3. Implement play/pause
4. Add progress bar
5. Test playback on various devices

### Phase 4: Polish
1. Add waveform visualization
2. Improve error handling
3. Add haptic feedback
4. Optimize performance
5. Accessibility improvements

## Open Questions

1. Should we support background recording?
   - **Decision:** No, keep it simple for v1

2. Should we allow editing/trimming voice notes?
   - **Decision:** No, out of scope for v1

3. Should we show waveform during playback?
   - **Decision:** Optional enhancement, not required

4. Should we support playback speed control?
   - **Decision:** Optional enhancement, not required

5. Maximum recording duration?
   - **Decision:** 5 minutes (300 seconds)

6. Should we cache downloaded audio files?
   - **Decision:** Yes, use URLCache for automatic caching

## References

- [AVAudioRecorder Documentation](https://developer.apple.com/documentation/avfoundation/avaudiorecorder)
- [AVAudioPlayer Documentation](https://developer.apple.com/documentation/avfoundation/avaudioplayer)
- [Audio Session Programming Guide](https://developer.apple.com/library/archive/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/)
- Existing implementation: MediaPicker.swift, MessageBubble.swift
