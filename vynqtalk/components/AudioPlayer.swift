//
//  AudioPlayer.swift
//  vynqtalk
//
//  Audio player component for voice notes
//

import SwiftUI
import AVFoundation

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var audioURL: URL?
    
    func loadAudio(from url: URL) {
        isLoading = true
        audioURL = url
        
        // Download audio data if it's a remote URL
        if url.scheme == "http" || url.scheme == "https" {
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil else {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                    }
                    #if DEBUG
                    print("❌ Failed to download audio: \(error?.localizedDescription ?? "Unknown error")")
                    #endif
                    return
                }
                
                DispatchQueue.main.async {
                    self.setupPlayer(with: data)
                }
            }.resume()
        } else {
            // Local file
            if let data = try? Data(contentsOf: url) {
                setupPlayer(with: data)
            } else {
                isLoading = false
            }
        }
    }
    
    private func setupPlayer(with data: Data) {
        do {
            // Setup audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0
            isLoading = false
            
            #if DEBUG
            print("🎵 Audio loaded. Duration: \(duration)s")
            #endif
            
        } catch {
            isLoading = false
            #if DEBUG
            print("❌ Failed to setup audio player: \(error)")
            #endif
        }
    }
    
    func togglePlayback() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func play() {
        audioPlayer?.play()
        isPlaying = true
        
        // Start timer to update current time
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        playbackTimer?.invalidate()
        playbackTimer = nil
        
        // Reset to beginning
        audioPlayer?.currentTime = 0
    }
    
    deinit {
        stop()
    }
}

// MARK: - Audio Player View

struct AudioPlayerView: View {
    @StateObject private var player = AudioPlayerManager()
    let audioURL: URL
    let isMe: Bool
    
    var formattedCurrentTime: String {
        formatTime(player.currentTime)
    }
    
    var formattedDuration: String {
        formatTime(player.duration)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                player.togglePlayback()
            }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.AccentColors.primary.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    if player.isLoading {
                        ProgressView()
                            .tint(AppTheme.AccentColors.primary)
                    } else {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.AccentColors.primary)
                    }
                }
            }
            .disabled(player.isLoading)
            
            // Waveform and progress
            VStack(alignment: .leading, spacing: 6) {
                // Waveform visualization
                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        ForEach(0..<30, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(waveformColor(for: index, width: geometry.size.width))
                                .frame(width: 2)
                                .frame(height: waveformHeight(for: index))
                        }
                    }
                }
                .frame(height: 32)
                
                // Time labels
                HStack {
                    Text(formattedCurrentTime)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.secondary)
                        .monospacedDigit()
                    
                    Spacer()
                    
                    Text(formattedDuration)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.tertiary)
                        .monospacedDigit()
                }
            }
        }
        .onAppear {
            player.loadAudio(from: audioURL)
        }
        .onDisappear {
            player.stop()
        }
    }
    
    private func waveformColor(for index: Int, width: CGFloat) -> Color {
        let progress = player.duration > 0 ? player.currentTime / player.duration : 0
        let barProgress = CGFloat(index) / 30.0
        
        if barProgress <= progress {
            return AppTheme.AccentColors.primary
        } else {
            return AppTheme.TextColors.tertiary.opacity(0.3)
        }
    }
    
    private func waveformHeight(for index: Int) -> CGFloat {
        // Create varied heights for visual interest
        let heights: [CGFloat] = [12, 20, 16, 28, 24, 18, 32, 22, 16, 26,
                                   20, 24, 18, 30, 16, 22, 28, 20, 24, 18,
                                   26, 20, 16, 24, 28, 22, 18, 26, 20, 16]
        return heights[index % heights.count]
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
