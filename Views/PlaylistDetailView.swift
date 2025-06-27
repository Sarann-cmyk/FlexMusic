//
//  PlaylistDetailView.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 24.03.2025.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers
import AVFoundation

struct PlaylistDetailView: View {
    @ObservedObject var playlist: Playlist
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showFileImporter = false
    @State private var importError: Error?
    @State private var showAlert = false
    @State private var songs: [Song] = []
    @Binding var selectedTab: Int
    @State private var pendingPlaylistName: String? = nil
    @State private var pendingFileURLs: [URL] = []
    
    init(playlist: Playlist, selectedTab: Binding<Int>) {
        self.playlist = playlist
        self._selectedTab = selectedTab
        _songs = State(initialValue: playlist.songsArray)
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            if songs.isEmpty {
                emptyStateView
            } else {
                songsListView
            }
        }
        .navigationTitle(playlist.name ?? "Playlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(playlist.name ?? "Playlist")
                    .foregroundColor(Color("playerControls"))
                    .font(.headline)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                newPlaylistButton
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                handlePlaylistCreation(with: urls)
            case .failure(let error):
                importError = error
                showAlert = true
            }
        }
        .alert("Import Error", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(importError?.localizedDescription ?? "Unknown error occurred")
        }
        .onAppear {
            // Загрузка песен при появлении представления
            songs = playlist.songsArray
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundGradient: some View {
            LinearGradient(
            gradient: Gradient(colors: [Color("topBacground"), Color("bottomBacground")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
    }
            
    private var emptyStateView: some View {
            VStack {
                Button {
                    showFileImporter = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color("playerControls"))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                Text("No songs in playlist")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("playerControls"))
                    .padding(.top, 8)
                
                Text("Tap the + button to add songs")
                    .font(.system(size: 14))
                    .foregroundColor(Color("playerControls").opacity(0.7))
                    .padding(.top, 4)
            }
        .foregroundColor(.white)
    }
    
    private var songsListView: some View {
        List {
            ForEach(songs) { song in
                SongRow(song: song)
                    .listRowBackground(Color.clear)
                    .contentShape(Rectangle())
                    .listRowInsets(EdgeInsets(top: 4, leading: 5, bottom: 4, trailing: 5))
                    .frame(height: 60)
                    .onTapGesture {
                        print("Tapped song: \(song.title ?? "Unknown")")
                        PlaylistManager.shared.setPlaylist(songs)
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
                        
                        Button(role: .destructive) {
                            removeFromPlaylist(song)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                        }
                    }
            }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
    }
    
    private var newPlaylistButton: some View {
        Button(action: {
            showFileImporter = true
        }) {
            Image(systemName: "plus")
                .foregroundColor(Color("playerControls"))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Import Handling
    
    private func handlePlaylistCreation(with urls: [URL]) {
        guard !urls.isEmpty else { return }
        let parentFolders = Set(urls.map { $0.deletingLastPathComponent().lastPathComponent })
        let playlistName: String
        if parentFolders.count == 1, let folder = parentFolders.first {
            playlistName = folder
        } else {
            playlistName = "Новий плейліст"
        }
        addPlaylistWithSongs(name: playlistName, urls: urls)
    }
    
    private func addPlaylistWithSongs(name: String, urls: [URL]) {
        let newPlaylist = Playlist(context: viewContext)
        newPlaylist.id = UUID()
        newPlaylist.name = name
        newPlaylist.colorHex = randomHexColor()
        newPlaylist.createdAt = Date()
        
        for url in urls {
            do {
                try importSongForLibrary(from: url, to: newPlaylist)
            } catch {
                importError = error
                showAlert = true
            }
        }
        do {
            try viewContext.save()
        } catch {
            importError = error
            showAlert = true
        }
    }
    
    private func importSongForLibrary(from url: URL, to playlist: Playlist) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let request = Song.fetchRequest()
        request.predicate = NSPredicate(format: "filePath == %@", url.path)
        if let existingSong = try? viewContext.fetch(request).first {
            playlist.addToSongs(existingSong)
            return
        }
        
        let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        let newSong = Song(context: viewContext)
        newSong.title = url.lastPathComponent
        newSong.filePath = url.path
        newSong.bookmarkData = bookmarkData
        newSong.isFavorite = false
        playlist.addToSongs(newSong)
        extractMetadataAsync(for: newSong, from: url)
    }
    
    private func extractMetadataAsync(for song: Song, from url: URL) {
        Task {
            do {
                var fileURL = url
                var needToStopAccess = false
                
                if !fileURL.isFileURL || !FileManager.default.fileExists(atPath: fileURL.path) {
                    if let bookmarkData = song.bookmarkData {
                        var isStale = false
                        do {
                            fileURL = try URL(resolvingBookmarkData: bookmarkData, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
                            if !fileURL.startAccessingSecurityScopedResource() {
                                print("Failed to access security scoped resource for metadata")
                                return
                            }
                            needToStopAccess = true
                        } catch {
                            print("Error resolving bookmark for metadata: \(error)")
                            return
                        }
                    } else {
                        print("No bookmark data available and URL is not accessible")
                        return
                    }
                }
                
                defer {
                    if needToStopAccess {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
                
                let asset = AVAsset(url: fileURL)
                
                var metadata: [AVMetadataItem] = []
                do {
                    metadata = try await asset.load(.metadata)
                } catch {
                    print("Failed to load metadata: \(error)")
                }
                
                for item in metadata {
                    guard let commonKey = item.commonKey else { continue }
                    
                    do {
                        switch commonKey {
                        case .commonKeyTitle:
                            if let title = try await item.load(.stringValue), !title.isEmpty {
                                song.title = title
                            }
                        case .commonKeyArtist:
                            song.artist = try await item.load(.stringValue)
                        case .commonKeyArtwork:
                            song.coverImageData = try await item.load(.dataValue)
                        case .commonKeyAlbumName:
                            let albumName = try await item.load(.stringValue)
                            print("Found album: \(albumName ?? "Unknown")")
                        default:
                            break
                        }
                    } catch {
                        print("Error loading metadata item with key \(commonKey): \(error)")
                    }
                }
                
                do {
                    let duration = try await asset.load(.duration)
                    song.duration = duration.seconds
                } catch {
                    print("Failed to load duration: \(error)")
                }
                
                try await MainActor.run {
                    if song.title == url.lastPathComponent, let title = cleanupFilename(song.title ?? "") {
                        song.title = title
                    }
                    
                    try viewContext.save()
                }
            } catch {
                print("Metadata extraction failed: \(error)")
            }
        }
    }
    
    private func cleanupFilename(_ filename: String) -> String? {
        let nameWithoutExtension = filename.split(separator: ".").dropLast().joined(separator: ".")
        if nameWithoutExtension.isEmpty {
            return filename
        }
        
        var cleanName = nameWithoutExtension.replacingOccurrences(of: "-", with: " ")
        cleanName = cleanName.replacingOccurrences(of: "_", with: " ")
        cleanName = cleanName.replacingOccurrences(of: "tagmp3", with: "")
        
        while cleanName.contains("  ") {
            cleanName = cleanName.replacingOccurrences(of: "  ", with: " ")
        }
        
        return cleanName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Error Handling
    
    private func showImportError(_ error: Error) {
        importError = error
        showAlert = true
    }
    
    private func deleteSongs(at offsets: IndexSet) {
        withAnimation {
            offsets.map { songs[$0] }.forEach { song in
                removeFromPlaylist(song)
            }
        }
    }
    
    private func toggleFavorite(_ song: Song) {
        withAnimation {
            song.isFavorite.toggle()
            if !song.isFavorite {
                playlist.removeFromSongs(song)
            }
            do {
                try viewContext.save()
                songs = playlist.songsArray
            } catch {
                print("Error toggling favorite: \(error)")
            }
        }
    }
    
    private func removeFromPlaylist(_ song: Song) {
        withAnimation {
            if song.isFavorite {
                song.isFavorite = false
            }
            
            playlist.removeFromSongs(song)
            
            let request = NSFetchRequest<Playlist>(entityName: "Playlist")
            request.predicate = NSPredicate(format: "ANY songs == %@", song)
            
            do {
                let playlists = try viewContext.fetch(request)
                if playlists.isEmpty {
                    viewContext.delete(song)
                }
                
                try viewContext.save()
                songs = playlist.songsArray
            } catch {
                showImportError(error)
            }
        }
    }
    
    private func randomHexColor() -> String {
        let colors = [
            "#007AFF", // .blue
            "#AF52DE", // .purple
            "#FF2D55", // .pink
            "#FF3B30", // .red
            "#FF9500", // .orange
            "#FFCC00", // .yellow
            "#34C759", // .green
            "#00C7BE", // .mint
            "#30B0C7", // .teal
            "#32ADE6", // .cyan
            "#5856D6"  // .indigo
        ]
        return colors.randomElement() ?? "#007AFF"
    }
}

// MARK: - Extensions

extension Playlist {
    var songsArray: [Song] {
        songs?.allObjects as? [Song] ?? []
    }
}

enum ImportError: Error {
    case fileAccessDenied
}

extension ImportError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Не вдалося отримати доступ до вибраного файлу"
        }
    }
}
