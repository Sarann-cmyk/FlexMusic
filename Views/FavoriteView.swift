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
    @EnvironmentObject private var localizationManager: LocalizationManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Song.title, ascending: true)],
        predicate: NSPredicate(format: "isFavorite == YES"),
        animation: .default)
    private var songs: FetchedResults<Song>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.createdAt, ascending: false)],
        predicate: NSPredicate(format: "name BEGINSWITH[c] %@", "★ "),
        animation: .default)
    private var favoritePlaylists: FetchedResults<Playlist>
    @Binding var selectedTab: Int
    
    @State private var showingAddPlaylist = false
    @State private var newPlaylistName = ""
    @State private var songToAdd: Song? = nil
    @State private var showAddToPlaylistMenu = false
    @State private var renamingPlaylist: Playlist? = nil
    @State private var renameText: String = ""
    @State private var sortOption: TrackSortOption = .dateAdded
    
    private var ungroupedFavoriteSongs: [Song] {
        songs.filter { song in
            !(favoritePlaylists.contains { playlist in
                (playlist.songsArray.contains { $0 == song })
            })
        }
    }
    
    private var sortedUngroupedFavoriteSongs: [Song] {
        TrackSortManager.sort(songs: ungroupedFavoriteSongs, by: sortOption)
    }
    
    // Додаю параметри для сітки плейлістів
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 20)
    ]
    
    var body: some View {
        let _ = localizationManager.currentLanguage
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
                
                VStack {
                    // Плейлісти Favorites (тепер горизонтальний ScrollView з HStack)
                    if !favoritePlaylists.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(favoritePlaylists) { playlist in
                                    NavigationLink(destination: PlaylistDetailView(playlist: playlist, selectedTab: $selectedTab)) {
                                        PlaylistItem(playlist: playlist)
                                            .frame(width: 100)
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteFavoritePlaylist(playlist)
                                        } label: {
                                            Label(localizationManager.localizedString(forKey: "delete"), systemImage: "trash")
                                        }
                                        Button {
                                            renameText = playlist.name?.replacingOccurrences(of: "★ ", with: "") ?? ""
                                            renamingPlaylist = playlist
                                        } label: {
                                            Label(localizationManager.localizedString(forKey: "rename_playlist"), systemImage: "pencil")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Основний контент
                    if songs.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 60))
                                .foregroundColor(Color("playerControls").opacity(0.7))
                            Text(localizationManager.localizedString(forKey: "no_favorite_songs"))
                                .font(.title2)
                                .foregroundColor(Color("playerControls"))
                            Text(localizationManager.localizedString(forKey: "add_songs_to_favorites"))
                                .font(.subheadline)
                                .foregroundColor(Color("playerControls").opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    } else {
                        List {
                            ForEach(sortedUngroupedFavoriteSongs, id: \.self) { song in
                                SongRow(song: song)
                                    .contentShape(Rectangle())
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 5, bottom: 4, trailing: 5))
                                    .frame(height: 60)
                                    .onTapGesture {
                                        PlaylistManager.shared.setPlaylist(Array(songs))
                                        AudioManager.shared.playSong(song)
                                        selectedTab = 1
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            toggleFavorite(song)
                                        } label: {
                                            Image(systemName: song.isFavorite ? "heart.slash" : "heart.fill")
                                                .font(.system(size: 12))
                                        }
                                        .tint(song.isFavorite ? .red : .pink)
                                        if !favoritePlaylists.isEmpty {
                                            Menu {
                                                ForEach(favoritePlaylists) { playlist in
                                                    Button(localizationManager.localizedString(forKey: "add_to_playlist") + " \(playlist.name?.replacingOccurrences(of: "★ ", with: "") ?? "Плейліст")") {
                                                        addSong(song, to: playlist)
                                                    }
                                                }
                                            } label: {
                                                Image(systemName: "text.badge.plus")
                                            }
                                        }
                                    }
                            }
                            .onDelete(perform: removeFromFavorites)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString(forKey: "favorites"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(localizationManager.localizedString(forKey: "favorites"))
                        .foregroundColor(Color("playerControls"))
                        .font(.headline)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Menu {
                            ForEach(TrackSortOption.allCases, id: \.self) { option in
                                Button(option.rawValue) {
                                    sortOption = option
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(Color("playerControls"))
                        }
                        Button(action: {
                            showingAddPlaylist = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(Color("playerControls"))
                        }
                    }
                }
            }
        }
        .alert(localizationManager.localizedString(forKey: "new_playlist"), isPresented: $showingAddPlaylist) {
            TextField(localizationManager.localizedString(forKey: "new_playlist"), text: $newPlaylistName)
            Button(localizationManager.localizedString(forKey: "cancel"), role: .cancel) {
                newPlaylistName = ""
            }
            Button(localizationManager.localizedString(forKey: "create")) {
                if !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty {
                    addFavoritePlaylist(name: newPlaylistName)
                    newPlaylistName = ""
                }
            }
        }
        .alert(localizationManager.localizedString(forKey: "rename_playlist"), isPresented: Binding<Bool>(
            get: { renamingPlaylist != nil },
            set: { if !$0 { renamingPlaylist = nil } }
        ), actions: {
            TextField(localizationManager.localizedString(forKey: "rename_playlist"), text: $renameText)
            Button(localizationManager.localizedString(forKey: "cancel"), role: .cancel) {
                renamingPlaylist = nil
                renameText = ""
            }
            Button(localizationManager.localizedString(forKey: "save")) {
                if let playlist = renamingPlaylist {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        playlist.name = "★ " + trimmed
                        do {
                            try viewContext.save()
                        } catch {
                            print("Error renaming playlist: \(error)")
                        }
                    }
                }
                renamingPlaylist = nil
                renameText = ""
            }
        }, message: {
            Text(localizationManager.localizedString(forKey: "enter_new_name"))
        })
    }
    
    private func addSong(_ song: Song, to playlist: Playlist) {
        // Перевіряємо, чи вже існує Song з таким filePath
        let request = Song.fetchRequest()
        request.predicate = NSPredicate(format: "filePath == %@", song.filePath ?? "")
        if let existingSong = try? viewContext.fetch(request).first {
            playlist.addToSongs(existingSong)
        } else {
            playlist.addToSongs(song)
        }
        do {
            try viewContext.save()
        } catch {
            print("Error adding song to playlist: \(error)")
        }
    }
    
    private func addFavoritePlaylist(name: String) {
        let playlist = Playlist(context: viewContext)
        playlist.id = UUID()
        playlist.name = "★ " + name
        playlist.colorHex = randomHexColor()
        playlist.createdAt = Date()
        do {
            try viewContext.save()
        } catch {
            print("Error saving favorite playlist: \(error)")
        }
    }
    
    private func randomHexColor() -> String {
        let colors = [
            "#007AFF", "#AF52DE", "#FF2D55", "#FF3B30", "#FF9500", "#FFCC00",
            "#34C759", "#00C7BE", "#30B0C7", "#32ADE6", "#5856D6"
        ]
        return colors.randomElement() ?? "#007AFF"
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
    
    // Додаю PlaylistItem як у LibraryView
    private func PlaylistItem(playlist: Playlist) -> some View {
        VStack(spacing: 4) {
            ZStack {
                if let coverData = findCoverImageData(for: playlist), let uiImage = UIImage(data: coverData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Rectangle()
                        .fill(Color(hex: playlist.colorHex ?? "#007AFF"))
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    Image(systemName: "music.note.list")
                        .font(.system(size: 22))
                        .foregroundColor(Color("playerControls"))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            VStack(spacing: 1) {
                Text(playlist.name?.replacingOccurrences(of: "★ ", with: "") ?? "")
                    .foregroundColor(Color("playerControls"))
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Text("\(playlist.songsArray.count) songs")
                    .foregroundColor(Color("playerControls").opacity(0.7))
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)
            .padding(.bottom, 4)
        }
    }
    
    // Пошук першої обкладинки з треків плейліста
    private func findCoverImageData(for playlist: Playlist) -> Data? {
        for song in playlist.songsArray {
            if let data = song.coverImageData, !data.isEmpty {
                return data
            }
        }
        return nil
    }
    
    private func deleteFavoritePlaylist(_ playlist: Playlist) {
        withAnimation {
            playlist.coverImageData = nil
            viewContext.delete(playlist)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting favorite playlist: \(error)")
            }
        }
    }
} 
