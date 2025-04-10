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
    @Environment(\.colorScheme) private var colorScheme
    @State private var showFileImporter = false
    @State private var importError: Error?
    @State private var showAlert = false
    @State private var songs: [Song] = []
    @Binding var selectedTab: Int
    
    // Колір для іконки плюса
    var plusIconColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
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
            ToolbarItem(placement: .navigationBarTrailing) {
                addSongsButton
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            DispatchQueue.main.async {
                handleImportResult(result)
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
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .padding()
            Text("No songs in playlist")
                .font(.title2)
            Text("Tap the + button to add songs")
                .foregroundColor(.secondary)
        }
        .foregroundColor(.white)
    }
    
    private var songsListView: some View {
        List {
            ForEach(songs) { song in
                SongRow(song: song)
                    .listRowBackground(Color.clear)
                    .contentShape(Rectangle())
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .frame(height: 66)
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
    
    private var addSongsButton: some View {
        Button {
            showFileImporter = true
        } label: {
            Image(systemName: "plus")
                .foregroundColor(plusIconColor)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Import Handling
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            importSongs(from: urls)
        case .failure(let error):
            showImportError(error)
        }
    }
    
    private func importSongs(from urls: [URL]) {
        for url in urls {
            do {
                try importSong(from: url)
            } catch {
                showImportError(error)
            }
        }
    }
    
    private func importSong(from url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Перевіряємо, чи існує вже пісня з таким шляхом
        if let existingSong = try findSong(withPath: url.path) {
            addToPlaylist(existingSong)
            try viewContext.save()
            songs = playlist.songsArray
            return
        }
        
        // Створюємо закладку (bookmark) для URL файлу
        let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        
        // Створюємо новий запис пісні
        let newSong = Song(context: viewContext)
        newSong.title = url.lastPathComponent
        newSong.filePath = url.path
        newSong.bookmarkData = bookmarkData
        newSong.isFavorite = false
        
        // Додаємо пісню до плейлиста
        addToPlaylist(newSong)
        
        // Завантажуємо метадані асинхронно
        extractMetadataAsync(for: newSong, from: url)
        
        try viewContext.save()
        // Оновлюємо список пісень
        songs = playlist.songsArray
    }
    
    private func findSong(withPath path: String) throws -> Song? {
        let request = Song.fetchRequest()
        request.predicate = NSPredicate(format: "filePath == %@", path)
        return try viewContext.fetch(request).first
    }
    
    private func addToPlaylist(_ song: Song) {
        if !playlist.songsArray.contains(song) {
            playlist.addToSongs(song)
            
            // Перевіряємо, чи потрібно встановити обкладинку плейлисту
            if playlist.coverImageData == nil && song.coverImageData != nil && song.coverImageData!.count > 0 {
                // Якщо плейлист ще не має обкладинки, але пісня має - встановлюємо
                playlist.coverImageData = song.coverImageData
                
                do {
                    try viewContext.save()
                    print("Обкладинку плейлиста встановлено з доданої пісні")
                } catch {
                    print("Помилка при збереженні обкладинки плейлиста: \(error)")
                }
            }
        }
    }
    
    private func extractMetadataAsync(for song: Song, from url: URL) {
        Task {
            do {
                // Забезпечуємо доступ до файлу перед витягуванням метаданих
                var fileURL = url
                var needToStopAccess = false
                
                // Якщо URL не має схеми file:// або вже недоступний, спробуємо відкрити через закладку
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
                
                // Відкладений виклик для гарантованого припинення доступу
                defer {
                    if needToStopAccess {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
                
                let asset = AVAsset(url: fileURL)
                
                // Використовуємо безпечний спосіб завантаження метаданих з обробкою помилок
                var metadata: [AVMetadataItem] = []
                do {
                    metadata = try await asset.load(.metadata)
                } catch {
                    print("Failed to load metadata: \(error)")
                    // Навіть якщо завантаження метаданих не вдалося, продовжимо отримання тривалості
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
                            // Додатково витягуємо назву альбому
                            let albumName = try await item.load(.stringValue)
                            print("Found album: \(albumName ?? "Unknown")")
                        default:
                            break
                        }
                    } catch {
                        print("Error loading metadata item with key \(commonKey): \(error)")
                    }
                }
                
                // Отримання тривалості також з обробкою помилок
                do {
                    let duration = try await asset.load(.duration)
                    song.duration = duration.seconds
                } catch {
                    print("Failed to load duration: \(error)")
                }
                
                try await MainActor.run {
                    // Якщо аудіофайл має назву з расширением, видаляємо його для кращого відображення
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
    
    // Допоміжна функція для очищення імені файлу від розширення та спеціальних символів
    private func cleanupFilename(_ filename: String) -> String? {
        // Видаляємо розширення файлу
        let nameWithoutExtension = filename.split(separator: ".").dropLast().joined(separator: ".")
        if nameWithoutExtension.isEmpty {
            return filename
        }
        
        // Замінюємо спеціальні символи на пробіли
        var cleanName = nameWithoutExtension.replacingOccurrences(of: "-", with: " ")
        cleanName = cleanName.replacingOccurrences(of: "_", with: " ")
        cleanName = cleanName.replacingOccurrences(of: "tagmp3", with: "")
        
        // Видаляємо повторюючі пробіли
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
    
    // Добавляем функцию для переключения избранного
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
    
    // Функция удаления из плейлиста
    private func removeFromPlaylist(_ song: Song) {
        withAnimation {
            // Если песня в избранном, удаляем её из избранного
            if song.isFavorite {
                song.isFavorite = false
            }
            
            // Удаляем песню из плейлиста
            playlist.removeFromSongs(song)
            
            // Если песня не используется в других плейлистах, удаляем запись про неї з бази даних
            let request = NSFetchRequest<Playlist>(entityName: "Playlist")
            request.predicate = NSPredicate(format: "ANY songs == %@", song)
            
            do {
                let playlists = try viewContext.fetch(request)
                if playlists.isEmpty {
                    // Видаляємо тільки запис у базі даних, оригінальний файл залишається незмінним
                    viewContext.delete(song)
                }
                
                try viewContext.save()
                // Обновляем список песен
                songs = playlist.songsArray
            } catch {
                showImportError(error)
            }
        }
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
            return "Could not access the selected file"
        }
    }
}
