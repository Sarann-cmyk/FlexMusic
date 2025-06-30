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
import SwiftUI

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var currentSong: Song? {
        didSet {
            if let song = currentSong {
                updateNowPlayingInfo()
                DynamicBackgroundManager.shared.updateBackground(from: song.coverImageData)
            }
        }
    }
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isShuffled = false
    @Published var repeatMode: RepeatMode = .none
    @Published var isPlayingFavorites = false
    @Published var currentPlaybackRate: Double = 1.0
    @Published var volume: Float = 1.0
    @AppStorage("skipSilenceAtEnd") var skipSilenceAtEnd = false
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var silenceDetectionTimer: Timer?
    private let silenceThreshold: Float = 0.01 // Поріг для визначення тиші в лінійній шкалі
    private let silenceDuration: TimeInterval = 3.0 // Тривалість тиші для пропуску
    private var silenceCount: Int = 0 // Лічильник перевірок тиші
    private let silenceLimit: Int = 30 // Кількість перевірок тиші для перемикання
    private let silenceCheckInterval: TimeInterval = 0.05 // Інтервал перевірки тиші
    private let silenceCheckStartTime: TimeInterval = 20.0 // Початок перевірки тиші за 10 секунд до кінця
    
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleAudioSessionInterruption),
                name: AVAudioSession.interruptionNotification,
                object: AVAudioSession.sharedInstance()
            )
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            if isPlaying {
                player?.pause()
                stopTimer()
                silenceDetectionTimer?.invalidate()
            }
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) && isPlaying {
                    player?.play()
                    startTimer()
                    if skipSilenceAtEnd {
                        startSilenceDetection()
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupAudioPlayer() {
        guard let song = currentSong,
              let filePath = song.filePath else { return }
        
        var fileURL: URL
        var needToStopAccess = false
        
        if let bookmarkData = song.bookmarkData {
            do {
                var isStale = false
                fileURL = try URL(resolvingBookmarkData: bookmarkData, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        song.bookmarkData = try fileURL.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
                        try song.managedObjectContext?.save()
                    }
                }
                
                if !fileURL.startAccessingSecurityScopedResource() {
                    fileURL = URL(fileURLWithPath: filePath)
                } else {
                    needToStopAccess = true
                }
            } catch {
                fileURL = URL(fileURLWithPath: filePath)
            }
        } else {
            fileURL = URL(fileURLWithPath: filePath)
        }
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let musicDirectory = documentsDirectory.appendingPathComponent("Music")
            let fileName = (filePath as NSString).lastPathComponent
            let alternativePath = musicDirectory.appendingPathComponent(fileName).path
            
            if FileManager.default.fileExists(atPath: alternativePath) {
                song.filePath = alternativePath
                try? song.managedObjectContext?.save()
                fileURL = URL(fileURLWithPath: alternativePath)
            } else {
                if needToStopAccess {
                    fileURL.stopAccessingSecurityScopedResource()
                }
                return
            }
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.delegate = self
            player?.enableRate = true
            player?.rate = Float(currentPlaybackRate)
            player?.volume = volume
            player?.isMeteringEnabled = true
            totalTime = player?.duration ?? 0
            
            if skipSilenceAtEnd {
                startSilenceDetection()
            }
            
            if needToStopAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func processAudioLevel(_ level: Float, timeRemaining: TimeInterval) {
        let isSilent = level < silenceThreshold
        
        if isSilent {
            silenceCount += 1
            
            if Double(silenceCount) * silenceCheckInterval >= silenceDuration {
                handleTrackEndDueToSilence()
                silenceCount = 0
            }
        } else {
            silenceCount = 0
        }
    }
    
    private func handleTrackEndDueToSilence() {
        silenceDetectionTimer?.invalidate()
        stopTimer()
        player?.stop()
        isPlaying = false
        currentTime = 0
        silenceCount = 0
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.skipSilenceAtEnd {
                self.startSilenceDetection()
            }
            
            switch self.repeatMode {
            case .none, .one:
                if let next = PlaylistManager.shared.playNext() {
                    self.playSong(next)
                }
            case .all:
                if let next = PlaylistManager.shared.playNext() {
                    self.playSong(next)
                } else if !PlaylistManager.shared.currentPlaylist.isEmpty {
                    PlaylistManager.shared.repeatPlaylist()
                    if let first = PlaylistManager.shared.currentPlaylist.first {
                        self.playSong(first)
                    }
                }
            }
        }
    }
    
    func startSilenceDetection() {
        guard let player = player, player.isPlaying else {
            return
        }
        
        silenceCount = 0
        silenceDetectionTimer?.invalidate()
        
        silenceDetectionTimer = Timer.scheduledTimer(withTimeInterval: silenceCheckInterval, repeats: true) { [weak self] _ in
            guard let self = self,
                  let player = self.player,
                  player.isPlaying else {
                self?.silenceDetectionTimer?.invalidate()
                return
            }
            
            player.updateMeters()
            let averagePower = player.averagePower(forChannel: 0)
            let linearPower = pow(10, averagePower / 20)
            let timeUntilEnd = player.duration - player.currentTime

            if timeUntilEnd <= self.silenceCheckStartTime {
                self.processAudioLevel(linearPower, timeRemaining: timeUntilEnd)
            } else {
                self.silenceCount = 0 // скидаємо лічильник, щоб не накопичувалась тиша
            }
        }
    }
    
    func playSong(_ song: Song) {
        guard let filePath = song.filePath else {
            print("Error: No file path found for song: \(song.title ?? "Unknown")")
            return
        }
        
        var fileURL: URL
        var needToStopAccess = false
        
        if let bookmarkData = song.bookmarkData {
            do {
                var isStale = false
                fileURL = try URL(resolvingBookmarkData: bookmarkData, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        song.bookmarkData = try fileURL.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
                        try song.managedObjectContext?.save()
                    }
                }
                
                if !fileURL.startAccessingSecurityScopedResource() {
                    fileURL = URL(fileURLWithPath: filePath)
                } else {
                    needToStopAccess = true
                }
            } catch {
                fileURL = URL(fileURLWithPath: filePath)
            }
        } else {
            fileURL = URL(fileURLWithPath: filePath)
        }
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let musicDirectory = documentsDirectory.appendingPathComponent("Music")
            let fileName = (filePath as NSString).lastPathComponent
            let alternativePath = musicDirectory.appendingPathComponent(fileName).path
            
            if FileManager.default.fileExists(atPath: alternativePath) {
                song.filePath = alternativePath
                try? song.managedObjectContext?.save()
                fileURL = URL(fileURLWithPath: alternativePath)
            } else {
                if needToStopAccess {
                    fileURL.stopAccessingSecurityScopedResource()
                }
                return
            }
        }
        
        do {
            player?.stop()
            timer?.invalidate()
            silenceDetectionTimer?.invalidate()
            
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.delegate = self
            player?.enableRate = true
            player?.prepareToPlay()
            player?.rate = Float(currentPlaybackRate)
            player?.isMeteringEnabled = true
            
            currentSong = song
            isPlaying = true
            totalTime = song.duration
            
            PlaylistManager.shared.setCurrentSong(song)
            
            if player?.play() == true {
                startTimer()
                if skipSilenceAtEnd {
                    startSilenceDetection()
                }
                
                if let duration = player?.duration {
                    totalTime = duration
                    song.duration = duration
                    try? song.managedObjectContext?.save()
                }
                
                song.playCount += 1
                try? song.managedObjectContext?.save()
                
                updateNowPlayingInfo()
            }
        } catch {
            print("Error playing song: \(error)")
        }
        
        if needToStopAccess {
            fileURL.stopAccessingSecurityScopedResource()
        }
    }
    
    func togglePlayPause() {
        if currentSong == nil {
            let favoriteSongs = PlaylistManager.shared.favoriteSongs()
            
            if let randomSong = favoriteSongs.randomElement() {
                playSong(randomSong)
                isPlayingFavorites = true
                PlaylistManager.shared.setPlaylist(favoriteSongs)
                return
            }
            return
        }
        
        if isPlaying {
            player?.pause()
            stopTimer()
            silenceDetectionTimer?.invalidate()
        } else {
            player?.enableRate = true
            player?.rate = Float(currentPlaybackRate)
            if player?.play() == true {
                startTimer()
                if skipSilenceAtEnd {
                    startSilenceDetection()
                }
            }
        }
        isPlaying.toggle()
        updateNowPlayingInfo()
    }
    
    func updateNowPlayingInfo() {
        guard let song = currentSong else { return }
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title ?? "Unknown",
            MPMediaItemPropertyArtist: song.artist ?? "Unknown",
            MPMediaItemPropertyPlaybackDuration: totalTime,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        if let coverImageData = song.coverImageData, let image = UIImage(data: coverImageData) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in return image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
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
        handleTrackEndDueToSilence()
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
        
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate * (isPlaying ? 1.0 : 0.0)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
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
        handleTrackEndDueToSilence()
    }
}

enum RepeatMode {
    case none
    case all
    case one
}
