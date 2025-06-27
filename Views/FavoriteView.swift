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
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(Color("playerControls").opacity(0.7))
                        
                        Text("No Favorite Songs")
                            .font(.title2)
                            .foregroundColor(Color("playerControls"))
                        
                        Text("Add songs to your favorites from the Library")
                            .font(.subheadline)
                            .foregroundColor(Color("playerControls").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(songs, id: \.self) { song in
                            SongRow(song: song)
                                .contentShape(Rectangle())
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 5, bottom: 4, trailing: 5))
                                .frame(height: 60)
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Favorites")
                        .foregroundColor(Color("playerControls"))
                        .font(.headline)
                }
            }
        }
    }
    
    private func removeFromFavorites(offsets: IndexSet) {
        withAnimation {
            offsets.map { songs[$0] }.forEach { song in
                song.isFavorite = false
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error removing from favorites: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleFavorite(_ song: Song) {
        withAnimation {
            song.isFavorite.toggle()
            
            do {
                try viewContext.save()
            } catch {
                print("Error toggling favorite: \(error.localizedDescription)")
            }
        }
    }
} 
