//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI
import AVFoundation
import CoreData
import UniformTypeIdentifiers

// Розширення для конвертації HEX в Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var storeKitManager: StoreKitManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.createdAt, ascending: false)],
        predicate: NSPredicate(format: "NOT (name BEGINSWITH[c] %@)", "★ "),
        animation: .default)
    private var playlists: FetchedResults<Playlist>
    
    @State private var showingAddPlaylist = false
    @State private var newPlaylistName = ""
    @Binding var selectedTab: Int
    @State private var showFileImporter = false
    @State private var importError: Error?
    @State private var showAlert = false
    @State private var showPurchaseAlert = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    
    private var hasFullAccess: Bool {
        storeKitManager.purchasedProductIDs.contains("com.flexmusic.fullaccess")
    }
    
    // Налаштування для сітки плейлистів
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 20)
    ]
    
    private func randomColor() -> Color {
        let colors: [Color] = [
            .blue, .purple, .pink, .red, .orange, 
            .yellow, .green, .mint, .teal, .cyan, .indigo
        ]
        return colors.randomElement() ?? .blue
    }
    
    private func addPlaylist(name: String) {
        if !hasFullAccess && playlists.count >= 1 {
            showPurchaseAlert = true
            return
        }
        withAnimation {
            let newPlaylist = Playlist(context: viewContext)
            newPlaylist.id = UUID()
            newPlaylist.name = name
            newPlaylist.colorHex = randomHexColor()
            newPlaylist.createdAt = Date()
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving playlist: \(error)")
            }
        }
    }
    
    // Генеруємо випадковий HEX-код кольору
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
    
    private func deletePlaylist(_ playlist: Playlist) {
        withAnimation {
            // Очищуємо обкладинку перед видаленням плейлиста
            playlist.coverImageData = nil
            
            viewContext.delete(playlist)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting playlist: \(error)")
            }
        }
    }
    
    // Добавляем новый компонент для плейлиста
    private func PlaylistItem(playlist: Playlist) -> some View {
        VStack(spacing: 6) {
            ZStack {
                // Використовуємо саме 1:1 співвідношення сторін
                Rectangle()
                    .fill(Color(hex: playlist.colorHex ?? "#007AFF"))
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Обкладинка всередині ZStack автоматично займає весь простір
                PlaylistCover(playlist: playlist)
                    .cornerRadius(12)
                    .clipped()
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .contextMenu {
                Button(role: .destructive) {
                    deletePlaylist(playlist)
                } label: {
                    Label(localizationManager.localizedString(forKey: "delete"), systemImage: "trash")
                }
            }
            
            VStack(spacing: 2) {
                Text(playlist.name ?? "")
                    .foregroundColor(Color("playerControls"))
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                Text("\(playlist.songsArray.count) songs")
                    .foregroundColor(Color("playerControls").opacity(0.7))
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
    }
    
    // Отдельный компонент для обложки плейлиста
    private func PlaylistCover(playlist: Playlist) -> some View {
        Group {
            if let coverData = playlist.coverImageData, 
               let uiImage = UIImage(data: coverData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                if let songWithCover = findSongWithCover(in: playlist),
                   let coverImageData = songWithCover.coverImageData,
                   let uiImage = UIImage(data: coverImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onAppear {
                            saveCoverToPlaylist(playlist: playlist, coverData: coverImageData)
                        }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: playlist.colorHex ?? "#007AFF"))
                        
                        Image(systemName: "music.note.list")
                            .font(.system(size: 30))
                            .foregroundColor(Color("playerControls"))
                    }
                }
            }
        }
    }
    
    // Функція для пошуку пісні з обкладинкою
    private func findSongWithCover(in playlist: Playlist) -> Song? {
        let songs = playlist.songsArray
        // Шукаємо першу пісню, яка має обкладинку
        return songs.first { song in
            guard let data = song.coverImageData else { return false }
            return data.count > 0 && UIImage(data: data) != nil
        }
    }
    
    // Функція для збереження обкладинки в плейлисті
    private func saveCoverToPlaylist(playlist: Playlist, coverData: Data) {
        if playlist.coverImageData == nil {
            playlist.coverImageData = coverData
            
            do {
                try viewContext.save()
                print("Зображення обкладинки збережено для плейлиста: \(playlist.name ?? "Unknown")")
            } catch {
                print("Помилка при збереженні обкладинки плейлиста: \(error)")
            }
        }
    }
    
    private func handlePlaylistCreation(with urls: [URL]) {
        if !hasFullAccess && playlists.count >= 1 {
            showPurchaseAlert = true
            return
        }
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
        if !hasFullAccess && playlists.count >= 1 {
            showPurchaseAlert = true
            return
        }
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
    
    var body: some View {
        let _ = localizationManager.currentLanguage
        NavigationView {
            ZStack {
                // Фоновый градиент
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("topBacground"),
                        Color("bottomBacground")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading) {
                        //                         Text(localizationManager.localizedString(forKey: "library"))
                        //                             .font(.system(size: 22, weight: .bold))
                        //                             .foregroundColor(Color("playerControls"))
                        //                             .padding(.horizontal)
                        //                             .padding(.top, 10)
                        //                             .padding(.bottom, 4)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(playlists) { playlist in
                                NavigationLink(
                                    destination: PlaylistDetailView(
                                        playlist: playlist,
                                        selectedTab: $selectedTab
                                    )
                                ) {
                                    PlaylistItem(playlist: playlist)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString(forKey: "library"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Видалено ToolbarItem(placement: .navigationBarLeading) для відновлення покупки
                ToolbarItem(placement: .principal) {
                    Text(localizationManager.localizedString(forKey: "library"))
                        .foregroundColor(Color("playerControls"))
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFileImporter = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color("playerControls"))
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
        .alert(localizationManager.localizedString(forKey: "Import Error"), isPresented: $showAlert) {
            Button(localizationManager.localizedString(forKey: "OK")) {}
        } message: {
            Text(importError?.localizedDescription ?? localizationManager.localizedString(forKey: "Unknown error occurred"))
        }
        .alert("Повна версія", isPresented: $showPurchaseAlert) {
            Button("Купити") {
                if let product = storeKitManager.products.first(where: { $0.productIdentifier == "com.flexmusic.fullaccess" }) {
                    storeKitManager.purchase(product)
                }
            }
            Button("Скасувати", role: .cancel) {}
        } message: {
            Text("Щоб додати більше одного плейлиста, потрібно купити повну версію.")
        }
        .alert(restoreMessage, isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}
