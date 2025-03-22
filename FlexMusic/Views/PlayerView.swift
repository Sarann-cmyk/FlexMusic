//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI
import CoreData

struct PlayerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var playlistManager = PlaylistManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("topBacground"),
                        Color("bottomBacground")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 50)
                    
                    // Cover Image
                    if let coverData = audioManager.currentSong?.coverImageData,
                       let uiImage = UIImage(data: coverData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 280, height: 280)
                            .cornerRadius(12)
                            .scaleEffect(audioManager.isPlaying ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: audioManager.isPlaying)
                    } else {
                        Image(systemName: "music.note")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 280, height: 280)
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .scaleEffect(audioManager.isPlaying ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: audioManager.isPlaying)
                    }
                    
                    Spacer()
                        .frame(height: 10)
                    
                    // Song Info
                    VStack(spacing: 12) {
                        Text(audioManager.currentSong?.title ?? "No Song Selected")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        Text(audioManager.currentSong?.artist ?? "Unknown Artist")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(height: 80)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { audioManager.currentTime },
                            set: { audioManager.seekAudio(to: $0) }
                        ), in: 0...audioManager.totalTime)
                            .accentColor(.white)
                        
                        HStack {
                            Text(formatTime(audioManager.currentTime))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text(formatTime(audioManager.totalTime))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Playback Controls
                    HStack(spacing: 40) {
                        Button(action: { audioManager.skipBackward() }) {
                            Image(systemName: "gobackward.10")
                                .font(.title2)
                                .foregroundColor(.white)
                        }

                        Button(action: { audioManager.playPreviousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }

                        Button(action: { audioManager.togglePlayPause() }) {
                            Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 55))
                                .foregroundColor(.white)
                        }   
                        
                        Button(action: { audioManager.playNextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: { audioManager.skipForward() }) {
                            Image(systemName: "goforward.10")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 
