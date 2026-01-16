//
//  VoiceRecorder.swift
//  vynqtalk
//
//  Voice note recording component
//

import SwiftUI
import AVFoundation

class VoiceRecorderManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var recordingURL: URL?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            #if DEBUG
            print("❌ Failed to setup audio session: \(error)")
            #endif
        }
    }
    
    func startRecording() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            guard let self = self, allowed else {
                #if DEBUG
                print("❌ Microphone permission denied")
                #endif
                return
            }
            
            DispatchQueue.main.async {
                self.beginRecording()
            }
        }
    }
    
    private func beginRecording() {
        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "voice_note_\(UUID().uuidString).m4a"
        recordingURL = tempDir.appendingPathComponent(fileName)
        
        guard let url = recordingURL else { return }
        
        // Audio settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            recordingTime = 0
            
            // Start timers
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let recorder = self.audioRecorder else { return }
                self.recordingTime = recorder.currentTime
            }
            
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self = self, let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)
                // Normalize from -160 to 0 dB to 0.0 to 1.0
                let normalizedLevel = max(0, (power + 160) / 160)
                self.audioLevel = normalizedLevel
            }
            
            #if DEBUG
            print("🎤 Started recording voice note")
            #endif
            
        } catch {
            #if DEBUG
            print("❌ Failed to start recording: \(error)")
            #endif
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        recordingTimer = nil
        levelTimer = nil
        isRecording = false
        audioLevel = 0
        
        #if DEBUG
        print("🎤 Stopped recording. Duration: \(recordingTime)s")
        #endif
        
        return recordingURL
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        recordingTimer = nil
        levelTimer = nil
        isRecording = false
        audioLevel = 0
        
        // Delete the recording
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        
        #if DEBUG
        print("🎤 Cancelled recording")
        #endif
    }
    
    func getRecordingData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }
}

// MARK: - Voice Recorder View

struct VoiceRecorderView: View {
    @StateObject private var recorder = VoiceRecorderManager()
    let onSend: (Data, TimeInterval) -> Void
    let onCancel: () -> Void
    
    @State private var isCancelling = false
    
    var formattedTime: String {
        let minutes = Int(recorder.recordingTime) / 60
        let seconds = Int(recorder.recordingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Cancel button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                recorder.cancelRecording()
                onCancel()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.AccentColors.error)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AppTheme.AccentColors.error.opacity(0.15))
                    )
            }
            
            // Waveform visualization
            HStack(spacing: 3) {
                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.AccentColors.primary)
                        .frame(width: 3)
                        .frame(height: waveformHeight(for: index))
                        .animation(.easeInOut(duration: 0.1), value: recorder.audioLevel)
                }
            }
            .frame(height: 40)
            
            // Time display
            Text(formattedTime)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.TextColors.primary)
                .monospacedDigit()
            
            Spacer()
            
            // Send button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                if let url = recorder.stopRecording(),
                   let data = try? Data(contentsOf: url) {
                    onSend(data, recorder.recordingTime)
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(AppTheme.AccentColors.primary)
                    )
                    .shadow(
                        color: AppTheme.AccentColors.primary.opacity(0.3),
                        radius: 8,
                        y: 2
                    )
            }
        }
        .padding(.horizontal, AppTheme.Layout.screenPadding)
        .padding(.vertical, 12)
        .background(AppTheme.BackgroundColors.secondary)
        .onAppear {
            recorder.startRecording()
        }
    }
    
    private func waveformHeight(for index: Int) -> CGFloat {
        // Create animated waveform effect
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 40
        
        // Use audio level to animate bars
        let level = CGFloat(recorder.audioLevel)
        
        // Create wave pattern
        let phase = Double(index) * 0.2
        let wave = sin(Date().timeIntervalSince1970 * 3 + phase)
        let normalizedWave = (wave + 1) / 2 // 0 to 1
        
        return baseHeight + (maxHeight - baseHeight) * level * CGFloat(normalizedWave)
    }
}

// MARK: - Voice Note Button

struct VoiceNoteButton: View {
    let onStartRecording: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onStartRecording()
        }) {
            Image(systemName: "mic.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.AccentColors.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(AppTheme.AccentColors.primary.opacity(0.15))
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(AppTheme.AnimationCurves.buttonPress, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
