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

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Song.title, ascending: true)],
        animation: .default)
    private var songs: FetchedResults<Song>
    @State private var showingAddSong = false
    @State private var showingFileImporter = false
    @State private var refreshID = UUID()
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                songList
                    .padding(.top, 8)
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFileImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSong) {
                AddSongView()
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("topBacground"),
                Color("bottomBacground")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var songList: some View {
        List {
            ForEach(songs, id: \.self) { song in
                SongRow(song: song)
                    .contentShape(Rectangle())
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .frame(height: 60)
                    .onTapGesture {
                        print("Tapped song: \(song.title ?? "Unknown")")
                        // Устанавливаем текущий плейлист как все песни
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
                        
                        Button(role: .destructive) {
                            deleteSong(song)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                        }
                    }
            }
            .onDelete(perform: deleteSongs)
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity)
        .id(refreshID)
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let files):
            for file in files {
                importSong(from: file)
            }
        case .failure(let error):
            print("Error importing files: \(error.localizedDescription)")
        }
    }
    
    private func importSong(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access the file")
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Создаем директорию для музыки, если её нет
        let musicDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Music")
        try? FileManager.default.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
        
        // Получаем имя файла
        let fileName = url.lastPathComponent
        let destinationURL = musicDirectory.appendingPathComponent(fileName)
        
        // Проверяем, существует ли уже файл
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("File already exists at path: \(destinationURL.path)")
            
            // Проверяем, существует ли уже такая песня в Core Data
            let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "filePath == %@", destinationURL.path)
            
            do {
                let existingSongs = try viewContext.fetch(fetchRequest)
                if existingSongs.isEmpty {
                    // Если файл существует, но песни нет в Core Data, создаем новую запись
                    let newSong = Song(context: viewContext)
                    newSong.title = fileName
                    newSong.filePath = destinationURL.path
                    newSong.isFavorite = false
                    
                    try viewContext.save()
                    
                    Task {
                        await extractMetadata(for: newSong, from: destinationURL)
                    }
                    
                    print("Added existing file to library: \(fileName)")
                } else {
                    print("Song with file path '\(destinationURL.path)' already exists in library")
                }
            } catch {
                print("Error checking for duplicates: \(error)")
            }
            
            return
        }
        
        do {
            // Копируем файл
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Создаем новую песню в Core Data
            let newSong = Song(context: viewContext)
            newSong.title = fileName
            newSong.filePath = destinationURL.path
            newSong.isFavorite = false
            
            // Сохраняем начальные данные
            try viewContext.save()
            
            // Извлекаем метаданные через AVAsset
            Task {
                await extractMetadata(for: newSong, from: destinationURL)
            }
            
            print("Successfully imported song: \(fileName)")
        } catch {
            print("Error importing song: \(error)")
            // Удаляем файл в случае ошибки
            try? FileManager.default.removeItem(at: destinationURL)
        }
    }
    
    private func extractMetadata(for song: Song, from url: URL) async {
        do {
            let asset = AVAsset(url: url)
            let metadata = try await asset.load(.metadata)
            
            for item in metadata {
                if let commonKey = item.commonKey {
                    do {
                        switch commonKey {
                        case .commonKeyTitle:
                            let title = try await item.load(.stringValue)
                            song.title = title
                        case .commonKeyArtist:
                            let artist = try await item.load(.stringValue)
                            song.artist = artist
                        case .commonKeyArtwork:
                            let artworkData = try await item.load(.dataValue)
                            song.coverImageData = artworkData
                        case .commonKeyAlbumName:
                            let album = try await item.load(.stringValue)
                            // Здесь можно добавить логику для работы с альбомами
                        default:
                            break
                        }
                    } catch {
                        print("Error loading metadata: \(error.localizedDescription)")
                    }
                }
            }
            
            // Получаем длительность
            let duration = try await asset.load(.duration)
            song.duration = duration.seconds
            
            try viewContext.save()
            
            // Обновляем UI в главном потоке
            await MainActor.run {
                viewContext.refresh(song, mergeChanges: true)
                refreshID = UUID()
            }
        } catch {
            print("Error extracting metadata: \(error.localizedDescription)")
        }
    }
    
    private func toggleFavorite(_ song: Song) {
        withAnimation {
            song.isFavorite.toggle()
            DispatchQueue.main.async {
                do {
                    try viewContext.save()
                    refreshID = UUID()
                } catch {
                    print("Error toggling favorite: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteSong(_ song: Song) {
        withAnimation {
            // Удаляем файл
            if let filePath = song.filePath {
                do {
                    try FileManager.default.removeItem(atPath: filePath)
                } catch {
                    print("Error deleting file: \(error.localizedDescription)")
                }
            }
            
            // Удаляем из Core Data
            viewContext.delete(song)
            DispatchQueue.main.async {
                do {
                    try viewContext.save()
                    refreshID = UUID()
                } catch {
                    print("Error deleting song: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteSongs(offsets: IndexSet) {
        withAnimation {
            offsets.map { songs[$0] }.forEach { song in
                if let filePath = song.filePath {
                    try? FileManager.default.removeItem(atPath: filePath)
                }
                viewContext.delete(song)
            }
            
            DispatchQueue.main.async {
                do {
                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
        }
    }
} 
