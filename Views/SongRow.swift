//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI

struct SongRow: View {
    let song: Song
    @ObservedObject private var songObject: Song
    @ObservedObject private var audioManager = AudioManager.shared
    
    init(song: Song) {
        self.song = song
        self.songObject = song
    }
    
    var isCurrent: Bool {
        audioManager.currentSong == song
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover Image
            if let coverImageData = song.coverImageData,
               let uiImage = UIImage(data: coverImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 55, height: 55)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 28))
                    .foregroundColor(Color("playerControls").opacity(0.7))
                    .frame(width: 55, height: 55)
                    .background(Color("playerControls").opacity(0.1))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            
            // Song Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(song.title ?? "Unknown Title")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color("playerControls"))
                        .lineLimit(1)
                }
                Text(song.artist ?? "Unknown Artist")
                    .font(.system(size: 14))
                    .foregroundColor(Color("playerControls").opacity(0.7))
                    .lineLimit(1)
                HStack {
                    // Duration
                    Text(formatDuration(song.duration))
                        .font(.system(size: 13))
                        .foregroundColor(Color("playerControls").opacity(0.5))
                    Spacer()
                }
            }
            Spacer()
            if isCurrent {
                AnimatedWaveform(isPlaying: $audioManager.isPlaying)
                    .frame(width: 24, height: 18)
                    .transition(.scale)
            }
            if songObject.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 18))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCurrent ? Color.accentColor.opacity(0.18) : Color("playerControls").opacity(0.05))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: isCurrent)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct AnimatedWaveform: View {
    @Binding var isPlaying: Bool
    @State private var phase: CGFloat = 0
    let barCount: Int = 5
    let barWidth: CGFloat = 3
    let barSpacing: CGFloat = 2
    let barHeight: CGFloat = 18
    let animationSpeed: Double = 0.25
    @State private var timer: Timer? = nil
    
    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: barWidth, height: barHeight * barScale(index: i))
            }
        }
        .onAppear {
            updateTimer()
        }
        .onChange(of: isPlaying) { _ in
            updateTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func barScale(index: Int) -> CGFloat {
        let base = CGFloat(index) / CGFloat(barCount - 1) * .pi * 2
        let sine = sin(base + phase)
        return 0.5 + 0.5 * abs(sine)
    }
    
    private func updateTimer() {
        timer?.invalidate()
        if isPlaying {
            timer = Timer.scheduledTimer(withTimeInterval: animationSpeed, repeats: true) { _ in
                withAnimation(.linear(duration: animationSpeed)) {
                    phase += .pi / 2
                }
            }
        } else {
            timer = nil
        }
    }
} 
