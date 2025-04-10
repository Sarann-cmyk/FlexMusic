//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FlexMusic")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Validate and fix data after loading the store
        CoreDataValidator.shared.validateAndFixData(in: container.viewContext)
    }
    
    // MARK: - Preview Helper
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Create sample data for preview
        let sampleSong = Song(context: viewContext)
        sampleSong.title = "Sample Song"
        sampleSong.artist = "Sample Artist"
        sampleSong.duration = 180.0
        sampleSong.genre = "Pop"
        sampleSong.year = 2024
        
        let sampleAlbum = Album(context: viewContext)
        sampleAlbum.title = "Sample Album"
        sampleAlbum.artist = "Sample Artist"
        sampleAlbum.songs = NSSet(array: [sampleSong])
        
        let samplePlaylist = Playlist(context: viewContext)
        samplePlaylist.title = "Sample Playlist"
        samplePlaylist.songs = NSSet(array: [sampleSong])
        
        try? viewContext.save()
        
        return controller
    }()
} 
