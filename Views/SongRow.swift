//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI

struct SongRow: View {
    @ObservedObject var song: Song
    
    var body: some View {
        HStack(spacing: 12) {
            // Album cover image
            AlbumCoverView(data: song.coverImageData)
                .frame(width: 50, height: 50)
                .cornerRadius(4)
            
            // Song metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title ?? "Unknown Song")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("textPrimary"))
                    .lineLimit(1)
                
                // Breaking up the complex expression
                let artistText = song.artist ?? "Unknown Artist"
                // Properly handle the album relationship
                let albumTitle = song.album?.title
                let albumSuffix = albumTitle != nil ? " • " + (albumTitle ?? "") : ""
                let subtitleText = artistText + albumSuffix
                
                Text(subtitleText)
                    .font(.system(size: 14))
                    .foregroundColor(Color("textSecondary"))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration
            if song.duration > 0 {
                Text(formatDuration(song.duration))
                    .font(.system(size: 14))
                    .foregroundColor(Color("textSecondary"))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 
