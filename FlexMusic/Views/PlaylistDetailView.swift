//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI
import CoreData

struct PlaylistDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let playlist: Playlist
    @State private var showingAddSongs = false
    
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
                    if let songs = playlist.songs as? Set<Song> {
                        ForEach(Array(songs), id: \.self) { song in
                            SongRow(song: song)
                                .contentShape(Rectangle())
                                .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteSongs)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(playlist.title ?? "Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSongs = true }) {
                        Label("Add Songs", systemImage: "plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingAddSongs) {
                AddSongsToPlaylistView(playlist: playlist)
            }
        }
    }
    
    private func deleteSongs(offsets: IndexSet) {
        if let songs = playlist.songs as? Set<Song> {
            let songArray = Array(songs)
            offsets.forEach { index in
                playlist.removeFromSongs(songArray[index])
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error removing songs from playlist: \(error.localizedDescription)")
            }
        }
    }
}

struct AddSongsToPlaylistView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let playlist: Playlist
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Song.title, ascending: true)],
        animation: .default)
    private var allSongs: FetchedResults<Song>
    @State private var selectedSongs: Set<Song> = []
    
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
                    ForEach(allSongs, id: \.self) { song in
                        SongRow(song: song)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedSongs.contains(song) {
                                    selectedSongs.remove(song)
                                } else {
                                    selectedSongs.insert(song)
                                }
                            }
                            .listRowBackground(selectedSongs.contains(song) ? Color.white.opacity(0.2) : Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(.white),
                trailing: Button("Add") { addSongs() }
                    .foregroundColor(.white)
                    .disabled(selectedSongs.isEmpty)
            )
        }
    }
    
    private func addSongs() {
        for song in selectedSongs {
            playlist.addToSongs(song)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error adding songs to playlist: \(error.localizedDescription)")
        }
        
        dismiss()
    }
} 
