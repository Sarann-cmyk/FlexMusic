//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import CoreData

class CoreDataValidator {
    static let shared = CoreDataValidator()
    
    private init() {}
    
    func validateAndFixData(in context: NSManagedObjectContext) {
        // Validate Songs
        validateSongs(in: context)
        
        // Validate Albums
        validateAlbums(in: context)
        
        // Validate Playlists
        validatePlaylists(in: context)
        
        // Save changes
        do {
            try context.save()
        } catch {
            print("Error saving context after validation: \(error)")
        }
    }
    
    private func validateSongs(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
        
        do {
            let songs = try context.fetch(fetchRequest)
            
            for song in songs {
                // Fix empty titles
                if song.title?.isEmpty ?? true {
                    song.title = "Untitled"
                }
                
                // Fix empty artists
                if song.artist?.isEmpty ?? true {
                    song.artist = "Unknown Artist"
                }
                
                // Fix empty genres
                if song.genre?.isEmpty ?? true {
                    song.genre = "Unknown Genre"
                }
                
                // Fix invalid durations
                if song.duration < 0 {
                    song.duration = 0
                }
                
                // Fix invalid years
                if song.year < 0 {
                    song.year = 0
                }
                
                // Validate file path
                if let filePath = song.filePath {
                    let fileManager = FileManager.default
                    if !fileManager.fileExists(atPath: filePath) {
                        // If file doesn't exist, try to find it in documents directory
                        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let fileName = (filePath as NSString).lastPathComponent
                            let newPath = documentsDirectory.appendingPathComponent(fileName).path
                            if fileManager.fileExists(atPath: newPath) {
                                song.filePath = newPath
                            } else {
                                // If file still doesn't exist, mark it as missing
                                print("Warning: Audio file missing for song: \(song.title ?? "Untitled")")
                            }
                        }
                    }
                }
            }
        } catch {
            print("Error validating songs: \(error)")
        }
    }
    
    private func validateAlbums(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
        
        do {
            let albums = try context.fetch(fetchRequest)
            
            for album in albums {
                // Fix empty titles
                if album.title?.isEmpty ?? true {
                    album.title = "Untitled Album"
                }
                
                // Fix empty artists
                if album.artist?.isEmpty ?? true {
                    album.artist = "Unknown Artist"
                }
                
                // Validate cover image path
                if let coverPath = album.coverImagePath {
                    let fileManager = FileManager.default
                    if !fileManager.fileExists(atPath: coverPath) {
                        album.coverImagePath = nil
                    }
                }
            }
        } catch {
            print("Error validating albums: \(error)")
        }
    }
    
    private func validatePlaylists(in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()
        
        do {
            let playlists = try context.fetch(fetchRequest)
            
            for playlist in playlists {
                // Fix empty titles
                if playlist.title?.isEmpty ?? true {
                    playlist.title = "Untitled Playlist"
                }
                
                // Validate songs in playlist
                if let songs = playlist.songs as? Set<Song> {
                    for song in songs {
                        if song.filePath == nil {
                            playlist.removeFromSongs(song)
                        }
                    }
                }
            }
        } catch {
            print("Error validating playlists: \(error)")
        }
    }
} 
