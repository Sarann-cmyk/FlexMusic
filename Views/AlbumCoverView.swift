//
//  AlbumCoverView.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI

struct AlbumCoverView: View {
    let data: Data?
    
    var body: some View {
        Group {
            if let imageData = data, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder for missing cover art
                ZStack {
                    Color.gray.opacity(0.3)
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview {
    AlbumCoverView(data: nil)
        .frame(width: 50, height: 50)
        .cornerRadius(4)
} 