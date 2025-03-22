//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI

struct YouMusic: View {
    @State private var showingAddPlaylist = false
    @State private var youtubePlaylistURL = ""
    @State private var playlists: [Playlist] = []
    
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
                
                // Content
                List {
                    ForEach(playlists, id: \.id) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                            PlaylistRow(playlist: playlist)
                                .contentShape(Rectangle())
                                .listRowBackground(Color.clear)
                        }
                    }
                    .onDelete(perform: deletePlaylists)
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Playlists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPlaylist = true }) {
                        Label("Add Playlist", systemImage: "plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingAddPlaylist) {
                AddPlaylistView(youtubePlaylistURL: $youtubePlaylistURL, playlists: $playlists)
            }
        }
    }
    
    private func deletePlaylists(offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
    }
}

struct AddPlaylistView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var youtubePlaylistURL: String
    @Binding var playlists: [Playlist]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("YouTube Playlist URL")) {
                    TextField("Enter URL", text: $youtubePlaylistURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") { addPlaylist() }
                    .disabled(youtubePlaylistURL.isEmpty)
            )
        }
    }
    
    private func addPlaylist() {
        // Здесь вы можете добавить код для извлечения информации о плейлисте с YouTube
        // и создания нового объекта Playlist с полученными данными.
        // Пока мы просто создадим объект Playlist с введенным URL.
        let newPlaylist = Playlist(id: UUID(), title: "New Playlist", youtubeURL: youtubePlaylistURL)
        playlists.append(newPlaylist)
        dismiss()
    }
}

struct Playlist: Identifiable {
    let id: UUID
    let title: String
    let youtubeURL: String
}

struct PlaylistRow: View {
    let playlist: Playlist
    
    var body: some View {
        HStack(spacing: 12) {
            // Playlist Icon
            Image(systemName: "music.note.list")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
            
            // Playlist Info
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(playlist.youtubeURL)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 4)
    }
}

struct PlaylistDetailView: View {
    let playlist: Playlist
    
    var body: some View {
        Text("Playlist Detail View")
            .navigationTitle(playlist.title)
    }
}
