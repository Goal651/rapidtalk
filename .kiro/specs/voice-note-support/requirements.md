# Voice Note Support - Requirements

## Overview
Add voice note recording, uploading, and playback functionality to RapidTalk chat application. Users should be able to record audio messages, send them through the chat, and play them back with visual feedback.

## User Stories

### US-1: Record Voice Note
**As a** chat user  
**I want to** record a voice note directly in the chat  
**So that** I can send quick audio messages without typing

**Acceptance Criteria:**
- Microphone button is visible in the chat input bar (next to attachment button)
- Tapping microphone button requests microphone permission (if not granted)
- Recording starts immediately after permission is granted
- Visual feedback shows recording is in progress (waveform animation, timer)
- User can cancel recording by swiping left or tapping cancel
- User can send recording by releasing button or tapping send
- Recording duration is tracked and displayed
- Maximum recording duration is 5 minutes
- Audio is recorded in a compressed format (AAC/M4A)

### US-2: Upload Voice Note
**As a** chat user  
**I want to** upload my recorded voice note to the server  
**So that** the recipient can receive and play it

**Acceptance Criteria:**
- Voice note is compressed before upload (target: under 1MB per minute)
- Upload progress is shown to user
- Duration metadata is calculated and sent with the file
- Upload uses existing REST endpoint: `POST /messages/upload`
- After upload, WebSocket message is sent with:
  - `type: "AUDIO"`
  - `content: "/uploads/UUID-filename.m4a"`
  - `duration: <seconds>`
  - `replyToId: <optional>`
- Upload failures show error message to user
- User can retry failed uploads

### US-3: Display Voice Note in Chat
**As a** chat user  
**I want to** see voice notes in the message bubble  
**So that** I can identify and play audio messages

**Acceptance Criteria:**
- Voice note messages show waveform icon
- Duration is displayed (e.g., "0:45")
- Play/pause button is visible
- Visual distinction from regular file attachments
- Sender's voice notes align right (purple gradient)
- Received voice notes align left (dark surface)
- Replied messages show above voice note (if applicable)
- Reactions can be added to voice notes

### US-4: Play Voice Note
**As a** chat user  
**I want to** play voice notes in the chat  
**So that** I can listen to audio messages

**Acceptance Criteria:**
- Tapping play button starts playback
- Play button changes to pause button during playback
- Progress bar shows current playback position
- Current time and total duration are displayed
- User can seek to different positions by dragging progress bar
- Playback continues when scrolling through messages
- Only one voice note plays at a time (playing new one stops current)
- Playback speed control (1x, 1.5x, 2x) - optional enhancement
- Audio plays through device speaker by default
- Audio respects device volume settings

### US-5: Voice Note Permissions
**As a** chat user  
**I want to** be prompted for microphone access  
**So that** I understand why the app needs this permission

**Acceptance Criteria:**
- First-time microphone access shows iOS permission dialog
- Permission denial shows helpful message with settings link
- Permission status is checked before each recording attempt
- User can grant permission from app settings if previously denied

## Technical Requirements

### Frontend (iOS/Swift)

#### New Components
1. **VoiceRecorder.swift**
   - AVAudioRecorder integration
   - Waveform visualization during recording
   - Timer display
   - Cancel/Send controls
   - Audio compression

2. **VoiceNotePlayer.swift**
   - AVAudioPlayer integration
   - Play/pause button
   - Progress bar with seek functionality
   - Time display (current/total)
   - Waveform visualization (optional)

3. **VoiceNoteButton.swift**
   - Microphone icon button
   - Long-press to record gesture
   - Slide to cancel gesture
   - Visual feedback during recording

#### Modified Files
1. **ChatScreen.swift**
   - Add microphone button to input bar
   - Handle voice recording state
   - Upload voice note with duration
   - Pass duration to WebSocket message

2. **MessageBubble.swift**
   - Enhanced AUDIO message display
   - Integrate VoiceNotePlayer component
   - Show duration in bubble
   - Handle playback state

3. **WSManager.swift**
   - Update `WebSocketSendMessage` to include `duration: Double?`
   - Send duration for AUDIO type messages

4. **Message.swift**
   - Already has `duration: Double?` field ✅

#### Audio Configuration
- Format: AAC (M4A container)
- Sample rate: 44.1 kHz
- Bit rate: 64 kbps (good quality, small size)
- Channels: Mono
- Target size: ~480 KB per minute

### Backend (Vapor/Swift)

#### Already Implemented ✅
- `duration: Double?` field in Message model
- DTOs updated to support duration
- Migration for duration column
- REST and WebSocket endpoints handle duration

#### No Backend Changes Required
The backend is already prepared to handle voice notes with duration metadata.

## Design Specifications

### Voice Recording UI
```
┌─────────────────────────────────────┐
│  [<] User Name          [...]       │
├─────────────────────────────────────┤
│                                     │
│  Messages...                        │
│                                     │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │ 🎤 Recording... 0:15        │   │
│  │ ▁▃▅▇▅▃▁▃▅▇▅▃▁ [Cancel][Send]│   │
│  └─────────────────────────────┘   │
│  [+] [Message field...] [🎤]       │
└─────────────────────────────────────┘
```

### Voice Note Message Bubble
```
Sent (right-aligned):
┌─────────────────────────────┐
│ 🎤 ▶ ━━━━━━━━━━━━━━━━━ 0:45 │
│     [Progress bar]           │
└─────────────────────────────┘
  12:34

Received (left-aligned):
┌─────────────────────────────┐
│ 🎤 ▶ ━━━━━━━━━━━━━━━━━ 1:23 │
│     [Progress bar]           │
└─────────────────────────────┘
  12:35
```

## Implementation Plan

### Phase 1: Voice Recording (Priority: High)
- [ ] Create VoiceRecorder component
- [ ] Add microphone button to ChatScreen
- [ ] Implement recording with AVAudioRecorder
- [ ] Add waveform visualization
- [ ] Add timer display
- [ ] Implement cancel/send controls
- [ ] Request microphone permissions

### Phase 2: Upload & Send (Priority: High)
- [ ] Calculate audio duration after recording
- [ ] Compress audio file
- [ ] Upload to REST endpoint
- [ ] Send WebSocket message with duration
- [ ] Handle upload errors
- [ ] Show upload progress

### Phase 3: Playback UI (Priority: High)
- [ ] Create VoiceNotePlayer component
- [ ] Update MessageBubble for AUDIO type
- [ ] Add play/pause button
- [ ] Add progress bar
- [ ] Display duration

### Phase 4: Playback Functionality (Priority: High)
- [ ] Implement AVAudioPlayer
- [ ] Handle play/pause
- [ ] Update progress bar during playback
- [ ] Implement seek functionality
- [ ] Stop other audio when starting new playback

### Phase 5: Polish & Testing (Priority: Medium)
- [ ] Test on different iOS versions
- [ ] Test with various audio lengths
- [ ] Test permission flows
- [ ] Test background/foreground transitions
- [ ] Add haptic feedback
- [ ] Optimize audio compression
- [ ] Add playback speed control (optional)

## Dependencies

### iOS Frameworks
- AVFoundation (AVAudioRecorder, AVAudioPlayer)
- AVKit (for audio session management)

### Permissions
- NSMicrophoneUsageDescription in Info.plist

### Existing Code
- APIClient.uploadMessageAttachment() ✅
- WebSocketManager.sendChatMessage() ✅
- Message model with duration field ✅
- MessageBubble component (needs enhancement)

## Success Metrics

### Functional
- Users can record voice notes up to 5 minutes
- Voice notes upload successfully 99%+ of the time
- Playback works on all supported iOS versions
- Audio quality is clear and understandable

### Performance
- Recording starts within 500ms of button press
- Upload completes within 5 seconds for 1-minute audio
- Playback starts within 1 second of play button press
- Audio files are under 500KB per minute

### User Experience
- Recording UI is intuitive (no tutorial needed)
- Playback controls are responsive
- Visual feedback is clear and helpful
- Error messages are actionable

## Out of Scope (Future Enhancements)

- Voice note transcription
- Voice effects/filters
- Audio editing (trim, cut)
- Voice note forwarding
- Download voice notes to device
- Playback speed control
- Waveform visualization during playback
- Background recording
- Voice note drafts

## Notes

- Backend already supports duration field ✅
- Follow existing patterns from image/video upload
- Use same compression strategy as images (keep under 1MB)
- Maintain consistent UI with other message types
- Ensure accessibility (VoiceOver support)
- Test with poor network conditions
- Consider battery impact of recording
