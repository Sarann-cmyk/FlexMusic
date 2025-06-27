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
        .accentColor(currentColorScheme == .dark ? .white : .blue)
        .onAppear {
            updateAppearance()
        }
        .onChange(of: themeManager.themeMode) { _ in
            updateAppearance()
        }
        .onChange(of: systemColorScheme) { _ in
            if themeManager.themeMode == .system {
                updateAppearance()
            }
        }
    }
    
    private func updateAppearance() {
        let isDarkMode = currentColorScheme == .dark
        
        // Настраиваем внешний вид TabBar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color("bottomBacground"))
        
        // Настраиваем цвет текста и иконок TabBar
        let textColor = isDarkMode ? UIColor.white : UIColor.darkGray
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: textColor]
        
        // Применяем настройки для TabBar
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Настраиваем внешний вид NavigationBar
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(Color("topBacground"))
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: textColor]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: textColor]
        
        // Применяем настройки для NavigationBar
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(ThemeManager.shared)
}
