//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI
import CoreData

struct PlayerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var playlistManager = PlaylistManager.shared
    @StateObject private var dynamicBackgroundManager = DynamicBackgroundManager.shared
    @State private var showingSleepPicker = false
    @State private var selectedSleepTime: TimeInterval = 0
    @State private var showingSpeedPicker = false
    @State private var currentPlaybackRate: Double = 1.0
    @State private var swipeOffset: CGFloat = 0
    @State private var isSwiping: Bool = false
    @State private var isInitialLoad = true
    
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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                if isInitialLoad || !dynamicBackgroundManager.isDynamicBackgroundEnabled {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("topBacground"),
                            Color("bottomBacground")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: dynamicBackgroundManager.backgroundGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: dynamicBackgroundManager.backgroundGradient)
                }
                
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 50)
                    
                    // Cover Image Container
                    VStack {
                        if let coverData = audioManager.currentSong?.coverImageData,
                           let uiImage = UIImage(data: coverData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: audioManager.isPlaying ? 330 : 320, height: audioManager.isPlaying ? 330 : 320)
                                .cornerRadius(12)
                                .scaleEffect(audioManager.isPlaying ? 1.2 : 1.0)
                                .offset(x: swipeOffset)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: audioManager.isPlaying)
                                .gesture(
                                    DragGesture(minimumDistance: 20)
                                        .onChanged { value in
                                            isSwiping = true
                                            swipeOffset = value.translation.width
                                        }
                                        .onEnded { value in
                                            isSwiping = false
                                            if value.translation.width < -50 {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    swipeOffset = -UIScreen.main.bounds.width
                                                    audioManager.playNextTrack()
                                                    swipeOffset = 0
                                                }
                                            } else if value.translation.width > 50 {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    swipeOffset = UIScreen.main.bounds.width
                                                    audioManager.playPreviousTrack()
                                                    swipeOffset = 0
                                                }
                                            } else {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    swipeOffset = 0
                                                }
                                            }
                                        }
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        audioManager.togglePlayPause()
                                    }
                                }
                        } else {
                            Image(systemName: "music.note")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: audioManager.isPlaying ? 320 : 280, height: audioManager.isPlaying ? 320 : 280)
                                .foregroundColor(Color("color_note"))
                                .background(Color("color_note").opacity(0.1))
                                .cornerRadius(12)
                                .scaleEffect(audioManager.isPlaying ? 1.2 : 1.0)
                                .offset(x: swipeOffset)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: audioManager.isPlaying)
                                .gesture(
                                    DragGesture(minimumDistance: 20)
                                        .onChanged { value in
                                            isSwiping = true
                                            swipeOffset = value.translation.width
                                        }
                                        .onEnded { value in
                                            isSwiping = false
                                            if value.translation.width < -50 {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    swipeOffset = -UIScreen.main.bounds.width
                                                    audioManager.playNextTrack()
                                                    swipeOffset = 0
                                                }
                                            } else if value.translation.width > 50 {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    swipeOffset = UIScreen.main.bounds.width
                                                    audioManager.playPreviousTrack()
                                                    swipeOffset = 0
                                                }
                                            } else {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    swipeOffset = 0
                                                }
                                            }
                                        }
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        audioManager.togglePlayPause()
                                    }
                                }
                        }
                    }
                    .frame(height: 320) // Фіксована висота контейнера
                    
                    Spacer()
                        .frame(height: 10)
                    
                    // Song Info
                    songInfoView
                    
                    // Progress Bar
                    progressBarView
                    
                    // Playback Controls
                    playbackControlsView
                    
                    // Additional Controls Row
                    additionalControlsView
                    
                    Spacer()
                }
            }
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Now Playing")
                        .foregroundColor(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor : Color("playerControls"))
                        .font(.headline)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
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
        }
        .onAppear {
            if isInitialLoad {
                isInitialLoad = false
                dynamicBackgroundManager.updateBackground(from: audioManager.currentSong?.coverImageData)
            }
        }
        .onChange(of: audioManager.currentSong) { _ in
            dynamicBackgroundManager.updateBackground(from: audioManager.currentSong?.coverImageData)
        }
    }
    
    private var songInfoView: some View {
        VStack(spacing: 12) {
            Text(audioManager.currentSong?.title ?? "No Song Selected")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor : Color("playerControls"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text(audioManager.currentSong?.artist ?? "Unknown Artist")
                .font(.body)
                .foregroundColor(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor.opacity(0.7) : Color("playerControls").opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .frame(height: 80)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    private var progressBarView: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let progress = (audioManager.totalTime > 0) ? CGFloat(audioManager.currentTime / audioManager.totalTime) : 0
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor.opacity(0.1) : Color("playerControls").opacity(0.1))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor.opacity(0.5) : Color("playerControls").opacity(0.5),
                                    dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor.opacity(0.3) : Color("playerControls").opacity(0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                    
                    Circle()
                        .fill(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor.opacity(0.5) : Color("playerControls").opacity(0.5))
                        .frame(width: 12, height: 12)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .offset(x: geometry.size.width * progress - 6)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                            audioManager.seekAudio(to: audioManager.totalTime * percentage)
                        }
                )
            }
            .frame(height: 20)
            
            HStack {
                Text(formatTime(audioManager.currentTime))
                    .font(.caption)
                    .foregroundColor(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor.opacity(0.5) : Color("playerControls").opacity(0.5))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                Text("-" + formatTime(audioManager.totalTime - audioManager.currentTime))
                    .font(.caption)
                    .foregroundColor(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor.opacity(0.5) : Color("playerControls").opacity(0.5))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.horizontal)
    }
    
    private var playbackControlsView: some View {
        HStack(spacing: 40) {
            Button(action: { audioManager.skipBackward() }) {
                Image(systemName: "gobackward.10")
                    .font(.title2)
                    .foregroundColor(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor : Color("playerControls"))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }

            Button(action: { audioManager.playPreviousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 30))
                    .foregroundColor(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor : Color("playerControls"))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }

            Button(action: { audioManager.togglePlayPause() }) {
                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 40))
                    .foregroundColor(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor : Color("playerControls"))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            
            Button(action: { audioManager.playNextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 30))
                    .foregroundColor(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor : Color("playerControls"))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            
            Button(action: { audioManager.skipForward() }) {
                Image(systemName: "goforward.10")
                    .font(.title2)
                    .foregroundColor(dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor : Color("playerControls"))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    private var additionalControlsView: some View {
        HStack(spacing: 50) {
            Button(action: { showingSleepPicker = true }) {
                VStack(spacing: 2) {
                    Image(systemName: selectedSleepTime > 0 ? "timer" : "timer.circle")
                        .font(.system(size: 28))
                        .foregroundColor(selectedSleepTime > 0 ? .green : (dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor : Color("playerControls")))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    if selectedSleepTime > 0 {
                        Text(formatSleepTime(selectedSleepTime))
                            .font(.caption2)
                            .foregroundColor(.green)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    } else {
                        Color.clear
                            .frame(height: 12)
                    }
                }
                .frame(width: 60, height: 45)
                .contentShape(Rectangle())
            }
            
            Button(action: toggleFavorite) {
                VStack(spacing: 2) {
                    Image(systemName: audioManager.currentSong?.isFavorite ?? false ? "heart.fill" : "heart")
                        .font(.system(size: 28))
                        .foregroundColor(audioManager.currentSong?.isFavorite ?? false ? .pink : (dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor : Color("playerControls")))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    Color.clear
                        .frame(height: 12)
                }
                .frame(width: 60, height: 45)
                .contentShape(Rectangle())
            }
            
            Button(action: { showingSpeedPicker = true }) {
                VStack(spacing: 2) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 28))
                        .foregroundColor(currentPlaybackRate != 1.0 ? .blue : (dynamicBackgroundManager.isDynamicBackgroundEnabled ? dynamicBackgroundManager.controlButtonColor : Color("playerControls")))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    if currentPlaybackRate != 1.0 {
                        Text(String(format: "%.2fx", currentPlaybackRate))
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    } else {
                        Color.clear
                            .frame(height: 12)
                    }
                }
                .frame(width: 60, height: 45)
                .contentShape(Rectangle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
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
        var onTimerSet: (TimeInterval) -> Void
        @StateObject private var dynamicBackgroundManager = DynamicBackgroundManager.shared
        
        var body: some View {
            ZStack {
                if dynamicBackgroundManager.isDynamicBackgroundEnabled {
                    LinearGradient(
                        colors: dynamicBackgroundManager.backgroundGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                } else {
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
                
                VStack(spacing: 20) {
                    Text("Sleep Timer")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(dynamicBackgroundManager.controlButtonColor)
                        .padding(.top, 20)
                    
                    Text("Music will stop playing after selected time")
                        .font(.subheadline)
                        .foregroundColor(dynamicBackgroundManager.controlButtonColor.opacity(0.7))
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
                    .foregroundColor(dynamicBackgroundManager.controlButtonColor)
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
                        .foregroundColor(dynamicBackgroundManager.controlButtonColor)
                    Spacer()
                    if selectedTime == time {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(dynamicBackgroundManager.controlButtonColor.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
    
    // Добавляем новую структуру для меню скорости воспроизведения
    struct PlaybackSpeedSheet: View {
        @Binding var isPresented: Bool
        @Binding var currentRate: Double
        var onSpeedSet: (Double) -> Void
        @StateObject private var dynamicBackgroundManager = DynamicBackgroundManager.shared
        
        private let speedOptions: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
        
        var body: some View {
            ZStack {
                if dynamicBackgroundManager.isDynamicBackgroundEnabled {
                    LinearGradient(
                        colors: dynamicBackgroundManager.backgroundGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                } else {
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
                
                VStack(spacing: 20) {
                    Text("Playback Speed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(dynamicBackgroundManager.controlButtonColor)
                        .padding(.top, 20)
                    
                    Text("Select playback speed for your music")
                        .font(.subheadline)
                        .foregroundColor(dynamicBackgroundManager.controlButtonColor.opacity(0.7))
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
                    .foregroundColor(dynamicBackgroundManager.controlButtonColor)
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
                        .foregroundColor(dynamicBackgroundManager.controlButtonColor)
                    Spacer()
                    if currentRate == speed {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(dynamicBackgroundManager.controlButtonColor.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
} 
