//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import Foundation
import CoreData

class PlaylistManager: ObservableObject {
    static let shared = PlaylistManager()
    
    @Published var currentPlaylist: [Song] = []
    @Published var currentIndex: Int = 0
    @Published var currentFavoriteIndex: Int = 0
    
    private init() {}
    
    func setPlaylist(_ songs: [Song]) {
        currentPlaylist = songs
        currentIndex = 0
    }
    
    func setCurrentSong(_ song: Song) {
        if let index = currentPlaylist.firstIndex(of: song) {
            currentIndex = index
        }
    }
    
    func playNext() -> Song? {
        guard currentIndex < currentPlaylist.count - 1 else { return nil }
        currentIndex += 1
        return currentPlaylist[currentIndex]
    }
    
    func playPrevious() -> Song? {
        guard currentIndex > 0 else { return nil }
        currentIndex -= 1
        return currentPlaylist[currentIndex]
    }
    
    func shufflePlaylist() {
        currentPlaylist.shuffle()
        currentIndex = 0
    }
    
    func repeatPlaylist() {
        currentIndex = 0
    }
    
    func favoriteSongs() -> [Song] {
        let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFavorite == true")
        
        do {
            let context = PersistenceController.shared.container.viewContext
            let favoriteSongs = try context.fetch(fetchRequest)
            return favoriteSongs
        } catch {
            print("Error fetching favorite songs: \(error)")
            return []
        }
    }
} 
