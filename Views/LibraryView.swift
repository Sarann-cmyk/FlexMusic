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
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Playlist.createdAt, ascending: false)],
        animation: .default)
    private var playlists: FetchedResults<Playlist>
    
    @State private var showingAddPlaylist = false
    @State private var newPlaylistName = ""
    @Binding var selectedTab: Int
    
    // Налаштування для сітки плейлистів
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 20)
    ]
    
    // Кольори залежні від теми
    var textColor: Color {
        colorScheme == .dark ? .white : .black.opacity(0.75)
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
    }
    
    // Колір для іконки плюс
    var plusIconColor: Color {
        colorScheme == .dark ? .white : .black.opacity(0.65)
    }
    
    private func randomColor() -> Color {
        let colors: [Color] = [
            .blue, .purple, .pink, .red, .orange, 
            .yellow, .green, .mint, .teal, .cyan, .indigo
        ]
        return colors.randomElement() ?? .blue
    }
    
    private func addPlaylist(name: String) {
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
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 0.5)
            )
            .contextMenu {
                Button(role: .destructive) {
                    deletePlaylist(playlist)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            VStack(spacing: 2) {
                Text(playlist.name ?? "")
                    .foregroundColor(textColor)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                Text("\(playlist.songsArray.count) songs")
                    .foregroundColor(secondaryTextColor)
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
                // Якщо в плейлиста вже є збережена обкладинка, показуємо її
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // Якщо обкладинки немає, спочатку перевіряємо пісні на наявність обкладинки
                if let songWithCover = findSongWithCover(in: playlist),
                   let coverImageData = songWithCover.coverImageData,
                   let uiImage = UIImage(data: coverImageData) {
                    // Знайдено пісню з обкладинкою - показуємо її і зберігаємо для плейлиста
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onAppear {
                            // Зберігаємо обкладинку як частину плейлиста
                            saveCoverToPlaylist(playlist: playlist, coverData: coverImageData)
                        }
                } else {
                    // Якщо жодна пісня не має обкладинки, показуємо стандартну іконку
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: playlist.colorHex ?? "#007AFF"))
                        
                        Image(systemName: "music.note.list")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
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
    
    // Кнопка создания нового плейлиста
    private var newPlaylistButton: some View {
        Button(action: {
            showingAddPlaylist = true
        }) {
            VStack(spacing: 6) {
                ZStack {
                    // Використовуємо саме 1:1 співвідношення сторін
                    Rectangle()
                        .fill(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(plusIconColor)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Text("Create Playlist")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textColor)
                            .padding(.top, 8)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 0.5)
                )
                
                VStack(spacing: 2) {
                    Text("New Playlist")
                        .foregroundColor(textColor)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    
                    Text("Add songs")
                        .foregroundColor(secondaryTextColor)
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 6)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Фоновый градиент
                Group {
                    if colorScheme == .dark {
                        // Для темної теми використовуємо однаковий колір з різною прозорістю
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("bottomBacground").opacity(0.95),
                                Color("bottomBacground")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    } else {
                        // Для світлої теми залишаємо як є
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
                }
                
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Your Library")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(textColor)
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            newPlaylistButton
                            
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
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("New Playlist", isPresented: $showingAddPlaylist) {
            TextField("Playlist Name", text: $newPlaylistName)
            
            Button("Cancel", role: .cancel) {
                newPlaylistName = ""
            }
            
            Button("Create") {
                if !newPlaylistName.isEmpty {
                    addPlaylist(name: newPlaylistName)
                    newPlaylistName = ""
                }
            }
        }
    }
}
