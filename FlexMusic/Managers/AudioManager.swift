import Foundation
import AVFoundation
import CoreData

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isShuffled = false
    @Published var repeatMode: RepeatMode = .none
    @Published var isPlayingFavorites = false
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    private override init() {
        super.init()
        setupAudioSession()
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
        
        var fileURL = URL(fileURLWithPath: filePath)
        
        // Проверяем существование файла
        if FileManager.default.fileExists(atPath: filePath) {
            print("File exists at path: \(filePath)")
        } else {
            print("File does not exist at path: \(filePath)")
            
            // Пробуем найти файл в директории Music
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let musicDirectory = documentsDirectory.appendingPathComponent("Music")
            let fileName = (filePath as NSString).lastPathComponent
            let alternativePath = musicDirectory.appendingPathComponent(fileName).path
            
            print("Checking alternative path: \(alternativePath)")
            if FileManager.default.fileExists(atPath: alternativePath) {
                print("File found at alternative path")
                // Обновляем путь в Core Data
                song.filePath = alternativePath
                try? song.managedObjectContext?.save()
                // Обновляем URL для воспроизведения
                fileURL = URL(fileURLWithPath: alternativePath)
            } else {
                print("File not found at alternative path either")
                return
            }
        }
        
        do {
            // Останавливаем текущее воспроизведение
            player?.stop()
            timer?.invalidate()
            
            // Создаем новый плеер
            player = try AVAudioPlayer(contentsOf: fileURL)
            player?.delegate = self
            player?.prepareToPlay()
            
            // Устанавливаем текущую песню
            currentSong = song
            isPlaying = true
            totalTime = song.duration
            
            // Обновляем текущий индекс в PlaylistManager
            PlaylistManager.shared.setCurrentSong(song)
            
            // Начинаем воспроизведение
            if player?.play() == true {
                startTimer()
                print("Started playing: \(song.title ?? "Unknown")")
                
                // Обновляем длительность после успешного воспроизведения
                if let duration = player?.duration {
                    totalTime = duration
                    song.duration = duration
                    try? song.managedObjectContext?.save()
                }
            } else {
                print("Failed to start playback")
            }
        } catch {
            print("Error playing song: \(error)")
            print("File path: \(fileURL.path)")
            print("File exists: \(FileManager.default.fileExists(atPath: fileURL.path))")
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
            player?.play()
            startTimer()
        }
        isPlaying.toggle()
    }
    
    func seekAudio(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
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
        }
    }
    
    func playPreviousTrack() {
        if let previousSong = PlaylistManager.shared.playPrevious() {
            playSong(previousSong)
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
