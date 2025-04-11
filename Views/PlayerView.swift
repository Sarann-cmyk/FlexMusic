//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI
import CoreData
import AVFoundation

struct PlayerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var playlistManager = PlaylistManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingSleepPicker = false
    @State private var selectedSleepTime: TimeInterval = 0
    @State private var showingSpeedPicker = false
    @State private var currentPlaybackRate: Double = 1.0
    @State private var dominantColor: Color? = nil
    
    private let sleepOptions: [TimeInterval] = [
        0,      // Выключено
        900,    // 15 минут
        1800,   // 30 минут
        2700,   // 45 минут
        3600,   // 1 час
        5400,   // 1.5 часа
        7200    // 2 часа
    ]
    
    private let playbackRates: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    
    // Кольори залежні від теми
    var textColor: Color {
        if themeManager.playerBackgroundMode == .dynamic && dominantColor != nil {
            return .white
        } else {
            return colorScheme == .dark ? .white : .black.opacity(0.75)
        }
    }
    
    var secondaryTextColor: Color {
        if themeManager.playerBackgroundMode == .dynamic && dominantColor != nil {
            return .white.opacity(0.7)
        } else {
            return colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
        }
    }
    
    var controlsColor: Color {
        if themeManager.playerBackgroundMode == .dynamic && dominantColor != nil {
            return .white
        } else {
            return colorScheme == .dark ? .white : .black.opacity(0.65)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон в залежності від налаштувань
                if themeManager.playerBackgroundMode == .staticGradient || dominantColor == nil {
                    // Стандартний градієнтний фон
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
                } else {
                    // Динамічний фон на основі обкладинки
                    LinearGradient(
                        gradient: Gradient(colors: [
                            dominantColor!.opacity(0.8),
                            dominantColor!.opacity(0.4),
                            Color.black.opacity(0.9)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 50)
                    
                    // Cover Image
                    if let coverData = audioManager.currentSong?.coverImageData,
                       let uiImage = UIImage(data: coverData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 280, height: 280)
                            .cornerRadius(12)
                            .scaleEffect(audioManager.isPlaying ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: audioManager.isPlaying)
                            .onAppear {
                                if themeManager.playerBackgroundMode == .dynamic {
                                    // Отримуємо домінуючий колір з обкладинки
                                    dominantColor = extractDominantColor(from: uiImage)
                                }
                            }
                    } else {
                        Image(systemName: "music.note")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 280, height: 280)
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .scaleEffect(audioManager.isPlaying ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: audioManager.isPlaying)
                    }
                    
                    Spacer()
                        .frame(height: 10)
                    
                    // Song Info
                    VStack(spacing: 12) {
                        Text(audioManager.currentSong?.title ?? "No Song Selected")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        
                        Text(audioManager.currentSong?.artist ?? "Unknown Artist")
                            .font(.body)
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(height: 80)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        Slider(value: Binding(
                            get: { audioManager.currentTime },
                            set: { audioManager.seekAudio(to: $0) }
                        ), in: 0...audioManager.totalTime)
                            .accentColor(controlsColor)
                        
                        HStack {
                            Text(formatTime(audioManager.currentTime))
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                            
                            Spacer()
                            
                            Text(formatTime(audioManager.totalTime))
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Playback Controls
                    VStack(spacing: 15) {
                        HStack(spacing: 40) {
                            Button(action: { audioManager.skipBackward() }) {
                                Image(systemName: "gobackward.10")
                                    .font(.title2)
                                    .foregroundColor(controlsColor)
                            }
                            .buttonStyle(DefaultButtonStyle())

                            Button(action: { audioManager.playPreviousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.title)
                                    .foregroundColor(controlsColor)
                            }
                            .buttonStyle(DefaultButtonStyle())

                            Button(action: { audioManager.togglePlayPause() }) {
                                Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 55))
                                    .foregroundColor(controlsColor)
                            }   
                            .buttonStyle(DefaultButtonStyle())
                            
                            Button(action: { audioManager.playNextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.title)
                                    .foregroundColor(controlsColor)
                            }
                            .buttonStyle(DefaultButtonStyle())
                            
                            Button(action: { audioManager.skipForward() }) {
                                Image(systemName: "goforward.10")
                                    .font(.title2)
                                    .foregroundColor(controlsColor)
                            }
                            .buttonStyle(DefaultButtonStyle())
                        }
                        
                        Spacer()
                            .frame(height: 15)
                        
                        // Additional Controls Row
                        HStack(spacing: 50) {
                            // Sleep Timer Button
                            Button(action: { showingSleepPicker = true }) {
                                VStack(spacing: 2) {
                                    Image(systemName: selectedSleepTime > 0 ? "timer" : "timer.circle")
                                        .font(.system(size: 28))
                                        .foregroundColor(selectedSleepTime > 0 ? .green : controlsColor)
                                    if selectedSleepTime > 0 {
                                        Text(formatSleepTime(selectedSleepTime))
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    } else {
                                        Color.clear
                                            .frame(height: 12)
                                    }
                                }
                                .frame(width: 60, height: 45)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(DefaultButtonStyle())
                            
                            // Favorite Button
                            Button(action: toggleFavorite) {
                                VStack(spacing: 2) {
                                    Image(systemName: audioManager.currentSong?.isFavorite ?? false ? "heart.fill" : "heart")
                                        .font(.system(size: 28))
                                        .foregroundColor(audioManager.currentSong?.isFavorite ?? false ? .pink : controlsColor)
                                    Color.clear
                                        .frame(height: 12)
                                }
                                .frame(width: 60, height: 45)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(DefaultButtonStyle())
                            
                            // Playback Speed Button
                            Button(action: { showingSpeedPicker = true }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "speedometer")
                                        .font(.system(size: 28))
                                        .foregroundColor(currentPlaybackRate != 1.0 ? .blue : controlsColor)
                                    if currentPlaybackRate != 1.0 {
                                        Text(String(format: "%.2fx", currentPlaybackRate))
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    } else {
                                        Color.clear
                                            .frame(height: 12)
                                    }
                                }
                                .frame(width: 60, height: 45)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(DefaultButtonStyle())
                        }
                        .frame(maxWidth: .infinity, alignment: .center)  // Центрируем весь HStack
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Оновлюємо навігаційний бар при відкритті вкладки
                if themeManager.themeMode == .dark {
                    NavigationBarStyler.applyDarkTheme()
                } else {
                    NavigationBarStyler.applyLightTheme()
                }
            }
            .onChange(of: themeManager.themeMode) { newTheme in
                // Оновлюємо навігаційний бар при зміні теми
                if newTheme == .dark {
                    NavigationBarStyler.applyDarkTheme()
                } else {
                    NavigationBarStyler.applyLightTheme()
                }
            }
            .onChange(of: UITraitCollection.current.userInterfaceStyle) { _ in
                // Оновлюємо навігаційний бар при зміні системної теми
                if themeManager.themeMode == .dark {
                    NavigationBarStyler.applyDarkTheme()
                } else {
                    NavigationBarStyler.applyLightTheme()
                }
            }
            .sheet(isPresented: $showingSleepPicker) {
                SleepTimerSheet(
                    isPresented: $showingSleepPicker,
                    selectedTime: $selectedSleepTime,
                    onTimerSet: setSleepTimer
                )
                .presentationDetents([.medium])
                .presentationBackground(Material.ultraThin)
            }
            .sheet(isPresented: $showingSpeedPicker) {
                PlaybackSpeedSheet(
                    isPresented: $showingSpeedPicker,
                    currentRate: $currentPlaybackRate,
                    onSpeedSet: setPlaybackRate
                )
                .presentationDetents([.medium])
                .presentationBackground(Material.ultraThin)
            }
            .onChange(of: themeManager.playerBackgroundMode) { newValue in
                if newValue == .staticGradient {
                    // Скидаємо домінуючий колір при зміні на статичний режим
                    dominantColor = nil
                } else if let coverData = audioManager.currentSong?.coverImageData,
                          let uiImage = UIImage(data: coverData) {
                    // Оновлюємо домінуючий колір при зміні на динамічний режим
                    dominantColor = extractDominantColor(from: uiImage)
                }
            }
            .onReceive(audioManager.$currentSong) { newSong in
                if themeManager.playerBackgroundMode == .dynamic, 
                   let coverData = newSong?.coverImageData,
                   let uiImage = UIImage(data: coverData) {
                    // Оновлюємо домінуючий колір при зміні пісні
                    dominantColor = extractDominantColor(from: uiImage)
                } else if themeManager.playerBackgroundMode == .staticGradient {
                    dominantColor = nil
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatSleepTime(_ time: TimeInterval) -> String {
        if time == 0 { return "Off" }
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func setSleepTimer(_ time: TimeInterval) {
        // Отменяем предыдущий таймер, если он был
        if selectedSleepTime > 0 {
            selectedSleepTime = 0
        }
        
        // Устанавливаем новый таймер
        selectedSleepTime = time
        if time > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + time) { [weak audioManager] in
                if self.selectedSleepTime == time {  // Проверяем, не был ли таймер отменен
                    audioManager?.togglePlayPause()
                    self.selectedSleepTime = 0
                }
            }
        }
    }
    
    private func toggleFavorite() {
        guard let song = audioManager.currentSong else { return }
        song.isFavorite.toggle()
        do {
            try viewContext.save()
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
    
    private func setPlaybackRate(_ rate: Double) {
        currentPlaybackRate = rate
        audioManager.setPlaybackRate(rate)
    }
    
    // Добавляем новую структуру внутри PlayerView
    struct SleepTimerSheet: View {
        @Binding var isPresented: Bool
        @Binding var selectedTime: TimeInterval
        @Environment(\.colorScheme) private var colorScheme
        var onTimerSet: (TimeInterval) -> Void
        
        var textColor: Color {
            colorScheme == .dark ? .white : .black.opacity(0.75)
        }
        
        var secondaryTextColor: Color {
            colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
        }
        
        var body: some View {
            ZStack {
                // Використовуємо тот же градієнт, що і в основному view
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
                
                VStack(spacing: 20) {
                    Text("Sleep Timer")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .padding(.top, 20)
                    
                    Text("Music will stop playing after selected time")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            TimerButton(title: "Turn Off", time: 0)
                            TimerButton(title: "15 minutes", time: 900)
                            TimerButton(title: "30 minutes", time: 1800)
                            TimerButton(title: "45 minutes", time: 2700)
                            TimerButton(title: "1 hour", time: 3600)
                            TimerButton(title: "1.5 hours", time: 5400)
                            TimerButton(title: "2 hours", time: 7200)
                        }
                        .padding()
                    }
                    
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(textColor)
                    .padding(.bottom, 30)
                }
            }
        }
        
        @ViewBuilder
        private func TimerButton(title: String, time: TimeInterval) -> some View {
            Button {
                onTimerSet(time)
                isPresented = false
            } label: {
                HStack {
                    Text(title)
                        .foregroundColor(textColor)
                    Spacer()
                    if selectedTime == time {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.03))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
    
    // Добавляем новую структуру для меню скорости воспроизведения
    struct PlaybackSpeedSheet: View {
        @Binding var isPresented: Bool
        @Binding var currentRate: Double
        @Environment(\.colorScheme) private var colorScheme
        var onSpeedSet: (Double) -> Void
        
        var textColor: Color {
            colorScheme == .dark ? .white : .black.opacity(0.75)
        }
        
        var secondaryTextColor: Color {
            colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
        }
        
        private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
        
        var body: some View {
            ZStack {
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
                
                VStack(spacing: 20) {
                    Text("Playback Speed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                        .padding(.top, 20)
                    
                    Text("Select playback speed for your music")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(speedOptions, id: \.self) { speed in
                                SpeedButton(speed: speed)
                            }
                        }
                        .padding()
                    }
                    
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(textColor)
                    .padding(.bottom, 30)
                }
            }
        }
        
        @ViewBuilder
        private func SpeedButton(speed: Double) -> some View {
            Button {
                onSpeedSet(speed)
                isPresented = false
            } label: {
                HStack {
                    Text(String(format: "%.2fx", speed))
                        .foregroundColor(textColor)
                    Spacer()
                    if currentRate == speed {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.03))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
    
    // Функція для отримання домінуючого кольору з обкладинки
    private func extractDominantColor(from image: UIImage) -> Color {
        guard let inputImage = CIImage(image: image) else { return Color("topBacground") }
        
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                    y: inputImage.extent.origin.y,
                                    z: inputImage.extent.size.width,
                                    w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage",
                                  parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else {
            return Color("topBacground")
        }
        
        guard let outputImage = filter.outputImage else {
            return Color("topBacground")
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)
        
        // Створюємо колір з отриманих значень RGB
        return Color(red: Double(bitmap[0]) / 255.0,
                    green: Double(bitmap[1]) / 255.0,
                    blue: Double(bitmap[2]) / 255.0)
    }
} 
