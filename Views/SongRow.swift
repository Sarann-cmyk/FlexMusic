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
    
    init(song: Song) {
        self.song = song
        self.songObject = song
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
                Text(song.title ?? "Unknown Title")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("playerControls"))
                    .lineLimit(1)
                
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
                    
                    // Favorite Indicator
                    if songObject.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.system(size: 14))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("playerControls").opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 
