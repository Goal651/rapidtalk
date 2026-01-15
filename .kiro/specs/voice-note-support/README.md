# Voice Note Support Specification

## Overview

This specification outlines the implementation of voice note recording, uploading, and playback functionality for RapidTalk chat application.

## Status

**Current Phase:** Requirements & Design  
**Backend Status:** ✅ Ready (duration field implemented)  
**Frontend Status:** 🔨 In Progress (Message model updated)

## Quick Links

- [Requirements](./requirements.md) - User stories and acceptance criteria
- [Design Document](./design.md) - Architecture and component specifications
- [Implementation Guide](./implementation-guide.md) - Step-by-step coding instructions

## What's Included

### User Features
- 🎤 Record voice notes up to 5 minutes
- 📤 Upload and send voice messages
- ▶️ Play voice notes with progress tracking
- 🔍 Seek to any position in playback
- 🎨 Visual waveform during recording
- ⏱️ Duration display and timer
- 🔄 Reply to messages with voice notes
- ❤️ React to voice notes

### Technical Features
- AVAudioRecorder integration
- AVAudioPlayer with progress tracking
- Audio compression (AAC format, ~480KB/min)
- Microphone permission handling
- Singleton AudioManager for playback control
- REST upload + WebSocket messaging
- Duration metadata tracking

## Implementation Phases

### Phase 1: Voice Recording ⏳
- Create VoiceRecorder component
- Add microphone button to ChatScreen
- Implement recording with waveform
- Handle permissions

### Phase 2: Upload & Send ⏳
- Calculate duration after recording
- Upload via REST API
- Send WebSocket message with duration
- Error handling

### Phase 3: Playback UI ⏳
- Create VoiceNotePlayer component
- Update MessageBubble for AUDIO type
- Add play/pause controls
- Add progress bar

### Phase 4: Playback Functionality ⏳
- Implement AVAudioPlayer
- Handle play/pause/seek
- Update progress in real-time
- Stop other audio when starting new

### Phase 5: Polish & Testing ⏳
- Test on various devices
- Optimize performance
- Add accessibility support
- Final bug fixes

## Key Components

### New Files
```
vynqtalk/
├── ViewModels/
│   └── AudioManager.swift          [NEW] - Singleton for audio playback
├── components/
│   ├── VoiceRecorder.swift         [NEW] - Recording UI with waveform
│   ├── VoiceNotePlayer.swift       [NEW] - Playback controls
│   └── VoiceNoteButton.swift       [NEW] - Microphone button (optional)
```

### Modified Files
```
vynqtalk/
├── Screens/
│   └── ChatScreen.swift            [MODIFY] - Add recording UI & upload
├── components/
│   └── MessageBubble.swift         [MODIFY] - Add voice note player
├── ViewModels/
│   └── WSManager.swift             [MODIFY] - Add duration to messages
└── Info.plist                      [MODIFY] - Add microphone permission
```

### Already Complete ✅
```
vynqtalk/
├── models/
│   └── Message.swift               [DONE] - Has duration field
└── services/
    └── client.swift                [DONE] - Has upload method
```

## Backend Requirements

### Already Implemented ✅
- `duration: Double?` field in Message model
- DTOs updated to support duration
- Migration for duration column
- REST endpoint: `POST /messages/upload`
- WebSocket message handling for AUDIO type

### No Backend Changes Required
The backend is fully prepared to handle voice notes.

## Getting Started

1. **Read the Requirements** - Understand user stories and acceptance criteria
2. **Review the Design** - Understand architecture and data flow
3. **Follow Implementation Guide** - Step-by-step coding instructions
4. **Test Thoroughly** - Use the testing checklist

## Dependencies

### iOS Frameworks
- AVFoundation (AVAudioRecorder, AVAudioPlayer)
- AVKit (audio session management)

### Permissions
- Microphone access (NSMicrophoneUsageDescription)

### Existing Code
- APIClient.uploadMessageAttachment() ✅
- WebSocketManager.sendChatMessage() ✅
- Message model with duration ✅
- MessageBubble component (needs enhancement)

## Success Criteria

### Functional
- ✅ Users can record voice notes up to 5 minutes
- ✅ Voice notes upload successfully 99%+ of the time
- ✅ Playback works on all supported iOS versions
- ✅ Audio quality is clear and understandable

### Performance
- ✅ Recording starts within 500ms
- ✅ Upload completes within 5s for 1-minute audio
- ✅ Playback starts within 1 second
- ✅ Audio files under 500KB per minute

### User Experience
- ✅ Recording UI is intuitive
- ✅ Playback controls are responsive
- ✅ Visual feedback is clear
- ✅ Error messages are actionable

## Out of Scope (Future)

- Voice note transcription
- Voice effects/filters
- Audio editing (trim, cut)
- Voice note forwarding
- Download to device
- Playback speed control
- Background recording
- Voice note drafts

## Questions?

Refer to the detailed documentation:
- [Requirements](./requirements.md) for user stories
- [Design Document](./design.md) for architecture
- [Implementation Guide](./implementation-guide.md) for code examples

## Timeline Estimate

- **Phase 1 (Recording):** 2-3 days
- **Phase 2 (Upload):** 1 day
- **Phase 3 (Playback UI):** 1-2 days
- **Phase 4 (Playback Logic):** 1-2 days
- **Phase 5 (Polish):** 1-2 days

**Total:** 6-10 days for complete implementation

## Notes

- Backend is already prepared ✅
- Follow existing patterns from image/video upload
- Use same compression strategy (keep under 1MB)
- Maintain consistent UI with other message types
- Ensure accessibility (VoiceOver support)
- Test with poor network conditions
