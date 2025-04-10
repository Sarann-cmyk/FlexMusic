//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI
import CoreData

struct FavoriteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Song.title, ascending: true)],
        predicate: NSPredicate(format: "isFavorite == YES"),
        animation: .default)
    private var songs: FetchedResults<Song>
    @Binding var selectedTab: Int
    
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
                if songs.isEmpty {
                    VStack {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .padding()
                        Text("No favorite songs")
                            .font(.title2)
                        Text("Heart your favorite songs to see them here")
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.white)
                } else {
                    List {
                        ForEach(songs, id: \.self) { song in
                            SongRow(song: song)
                                .contentShape(Rectangle())
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                .frame(height: 66)
                                .onTapGesture {
                                    // Устанавливаем текущий плейлист как все избранные песни
                                    PlaylistManager.shared.setPlaylist(Array(songs))
                                    AudioManager.shared.playSong(song)
                                    selectedTab = 1 // Переключаемся на вкладку Player
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        toggleFavorite(song)
                                    } label: {
                                        Image(systemName: song.isFavorite ? "heart.slash" : "heart.fill")
                                            .font(.system(size: 12))
                                    }
                                    .tint(song.isFavorite ? .red : .pink)
                                }
                        }
                        .onDelete(perform: removeFromFavorites)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func toggleFavorite(_ song: Song) {
        withAnimation {
            song.isFavorite.toggle()
            do {
                try viewContext.save()
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
    
    private func removeFromFavorites(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let song = songs[index]
                song.isFavorite = false
            }
            do {
                try viewContext.save()
            } catch {
                print("Error removing from favorites: \(error)")
            }
        }
    }
} 
