//
//  ContentView.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers
import AVFoundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab = 1
    
    var currentColorScheme: ColorScheme {
        themeManager.themeMode == .system ? systemColorScheme : 
            (themeManager.themeMode == .dark ? .dark : .light)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FavoriteView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
                .tag(0)
            
            PlayerView()
                .tabItem {
                    Label("Player", systemImage: "play.circle.fill")
                }
                .tag(1)
            
            LibraryView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Library", systemImage: "music.note.list")
                }
                .tag(2)
            
            // Добавляем вкладку Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .accentColor(.pink) // Встановлюємо акцентний колір напряму
        .onAppear {
            // Скидаємо попередні налаштування перед застосуванням нових
            UIKitReset.resetAllAppearances()
            
            // Застосовуємо налаштування TabBar залежно від поточної теми
            if currentColorScheme == .dark {
                TabBarAppearance.configureForDarkMode()
                print("ContentView: Applied DARK theme with WHITE icons")
            } else {
                TabBarAppearance.configureForLightMode()
                print("ContentView: Applied LIGHT theme with BLACK icons")
            }
        }
        .onChange(of: currentColorScheme) { newColorScheme in
            // Спочатку скидаємо попередні налаштування
            UIKitReset.resetAllAppearances()
            
            // Потім застосовуємо нові налаштування
            if newColorScheme == .dark {
                TabBarAppearance.configureForDarkMode()
                print("ContentView: Changed to DARK theme with WHITE icons")
            } else {
                TabBarAppearance.configureForLightMode()
                print("ContentView: Changed to LIGHT theme with BLACK icons")
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(ThemeManager.shared)
}

