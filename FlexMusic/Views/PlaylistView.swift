//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI
import CoreData

struct PlaylistView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.title, ascending: true)],
        animation: .default)
    private var playlists: FetchedResults<Playlist>
    @State private var showingAddPlaylist = false
    @State private var selectedPlaylist: Playlist?
    
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
                    ForEach(playlists, id: \.self) { playlist in
                        PlaylistRow(playlist: playlist)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPlaylist = playlist
                            }
                            .listRowBackground(Color.clear)
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
                AddPlaylistView()
            }
            .sheet(item: $selectedPlaylist) { playlist in
                PlaylistDetailView(playlist: playlist)
            }
        }
    }
    
    private func deletePlaylists(offsets: IndexSet) {
        withAnimation {
            offsets.map { playlists[$0] }.forEach { playlist in
                viewContext.delete(playlist)
            }
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
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
                Text(playlist.title ?? "Untitled Playlist")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let songs = playlist.songs as? Set<Song> {
                    Text("\(songs.count) songs")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 4)
    }
} 
