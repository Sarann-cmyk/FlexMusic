//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import Foundation
import AVFoundation
import CoreData
import MediaPlayer

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isShuffled = false
    @Published var repeatMode: RepeatMode = .none
    @Published var isPlayingFavorites = false
    @Published var currentPlaybackRate: Double = 1.0
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func playSong(_ song: Song) {
        guard let filePath = song.filePath else {
            print("Error: No file path found for song: \(song.title ?? "Unknown")")
            return
        }
        
        print("\n=== Attempting to play song ===")
        print("Title: \(song.title ?? "Unknown")")
        print("Stored path: \(filePath)")
        
        var fileURL: URL
        var needToStopAccess = false
        
        // Спочатку спробуємо використати закладку (bookmark), якщо вона доступна
        if let bookmarkData = song.bookmarkData {
            print("Bookmark data found, attempting to resolve")
            do {
                var isStale = false
                fileURL = try URL(resolvingBookmarkData: bookmarkData, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                // Перевіряємо, чи закладка застаріла - якщо так, оновлюємо її
                if isStale {
                    print("Bookmark is stale, updating")
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        song.bookmarkData = try fileURL.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
                        try song.managedObjectContext?.save()
                    }
                }
                
                // Отримуємо доступ до файлу через захищений ресурс
                if !fileURL.startAccessingSecurityScopedResource() {
                    print("Failed to access security scoped resource")
                    // Спробуємо використати filePath як резервний варіант
                    fileURL = URL(fileURLWithPath: filePath)
                } else {
                    needToStopAccess = true
                    print("Successfully accessed security scoped resource")
                }
            } catch {
                print("Error resolving bookmark: \(error)")
                // Використовуємо filePath як резервний варіант
                fileURL = URL(fileURLWithPath: filePath)
            }
        } else {
            // Якщо закладка недоступна, використовуємо filePath
            print("No bookmark data available, using file path")
            fileURL = URL(fileURLWithPath: filePath)
        }
        
        // Перевіряємо існування файлу
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            print("File does not exist at path: \(fileURL.path)")
            
            // Пробуємо знайти файл в директории Music як останній варіант
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let musicDirectory = documentsDirectory.appendingPathComponent("Music")
            let fileName = (filePath as NSString).lastPathComponent
            let alternativePath = musicDirectory.appendingPathComponent(fileName).path
            
            print("Checking alternative path: \(alternativePath)")
            if FileManager.default.fileExists(atPath: alternativePath) {
                print("File found at alternative path")
                // Обновляємо шлях в Core Data
                song.filePath = alternativePath
                try? song.managedObjectContext?.save()
                // Обновляємо URL для відтворення
                fileURL = URL(fileURLWithPath: alternativePath)
            } else {
                print("File not found at alternative path either")
                
                // Якщо доступ був відкритий, закриваємо його
                if needToStopAccess {
                    fileURL.stopAccessingSecurityScopedResource()
                }
                return
            }
        }
        
        do {
            // Зупиняємо поточне відтворення
            player?.stop()
            timer?.invalidate()
            
            // Створюємо новий плеєр
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.delegate = self
            player?.enableRate = true
            player?.prepareToPlay()
            player?.rate = Float(currentPlaybackRate)
            
            // Встановлюємо поточну пісню
            currentSong = song
            isPlaying = true
            totalTime = song.duration
            
            // Оновлюємо поточний індекс в PlaylistManager
            PlaylistManager.shared.setCurrentSong(song)
            
            // Починаємо відтворення
            if player?.play() == true {
                startTimer()
                print("Started playing: \(song.title ?? "Unknown")")
                
                // Оновлюємо тривалість після успішного відтворення
                if let duration = player?.duration {
                    totalTime = duration
                    song.duration = duration
                    try? song.managedObjectContext?.save()
                }
                
                // Оновлюємо інформацію про поточний трек
                updateNowPlayingInfo()
            } else {
                print("Failed to start playback")
            }
        } catch {
            print("Error playing song: \(error)")
            print("File path: \(fileURL.path)")
            print("File exists: \(FileManager.default.fileExists(atPath: fileURL.path))")
        }
        
        // Якщо доступ був відкритий, закриваємо його після початку відтворення
        if needToStopAccess {
            fileURL.stopAccessingSecurityScopedResource()
        }
    }
    
    func togglePlayPause() {
        if currentSong == nil {
            // Получаем избранные песни
            let favoriteSongs = PlaylistManager.shared.favoriteSongs()
            
            if let randomSong = favoriteSongs.randomElement() {
                playSong(randomSong)
                isPlayingFavorites = true
                PlaylistManager.shared.setPlaylist(favoriteSongs)
                return
            } else {
                print("Нет избранных песен для воспроизведения")
                return
            }
        }
        
        if isPlaying {
            player?.pause()
            stopTimer()
        } else {
            player?.enableRate = true
            player?.rate = Float(currentPlaybackRate)
            player?.play()
            startTimer()
        }
        isPlaying.toggle()
        updateNowPlayingInfo() // Обновляем информацию о треке
    }
    
    func updateNowPlayingInfo() {
        guard let song = currentSong else { return }
        
        print("Updating Now Playing Info for song: \(song.title ?? "Unknown")")
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title ?? "Unknown",
            MPMediaItemPropertyArtist: song.artist ?? "Unknown",
            MPMediaItemPropertyPlaybackDuration: totalTime,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        // Загружаем обложку из данных песни
        if let coverImageData = song.coverImageData, let image = UIImage(data: coverImageData) {
            print("Artwork data found, size: \(coverImageData.count) bytes")
            print("Artwork image size: \(image.size)")
            
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            
            print("Artwork added to Now Playing Info")
        } else {
            print("No artwork data found for the song")
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("Now Playing Info updated")
    }
    
    func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNextTrack()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPreviousTrack()
            return .success
        }
        commandCenter.seekForwardCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        }
        commandCenter.seekBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
                     guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
                     self?.seekAudio(to: event.positionTime)
                     return .success
                 }
             }
    
    
    func seekAudio(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
        updateNowPlayingInfo()
    }
    
    func skipForward() {
        guard let player = player else { return }
        player.currentTime = min(player.currentTime + 10, player.duration)
    }
    
    func skipBackward() {
        guard let player = player else { return }
        player.currentTime = max(player.currentTime - 10, 0)
    }
    
    func playNextTrack() {
        if let nextSong = PlaylistManager.shared.playNext() {
            playSong(nextSong)
            updateNowPlayingInfo()
        }
    }
    
    func playPreviousTrack() {
        if let previousSong = PlaylistManager.shared.playPrevious() {
            playSong(previousSong)
            updateNowPlayingInfo()
        }
    }
    
    func toggleShuffle() {
        isShuffled.toggle()
        PlaylistManager.shared.shufflePlaylist()
    }
    
    func toggleRepeat() {
        switch repeatMode {
        case .none:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .none
        }
    }
    
    func setPlaybackRate(_ rate: Double) {
        currentPlaybackRate = rate
        player?.enableRate = true
        player?.rate = Float(rate)
        
        // Обновляем информацию о воспроизведении для системного плеера
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate * (isPlaying ? 1.0 : 0.0)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        print("Playback rate set to: \(rate)")
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.currentTime = self?.player?.currentTime ?? 0
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        stopTimer()
        
        // Обработка следующего трека в зависимости от режима воспроизведения
        switch repeatMode {
        case .none:
            if let nextSong = PlaylistManager.shared.playNext() {
                playSong(nextSong)
            }
        case .all:
            if let nextSong = PlaylistManager.shared.playNext() {
                playSong(nextSong)
            } else {
                PlaylistManager.shared.repeatPlaylist()
                if let firstSong = PlaylistManager.shared.currentPlaylist.first {
                    playSong(firstSong)
                }
            }
        case .one:
            playSong(currentSong!)
        }
    }
}

enum RepeatMode {
    case none
    case all
    case one
}
