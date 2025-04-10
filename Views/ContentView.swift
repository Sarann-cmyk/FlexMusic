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
        let textColor = UIColor.white // Завжди білий для темної теми
        let accentUIColor = UIColor(Color.pink) // UIColor із нашого accent color
        
        // Налаштування кольорів тексту
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accentUIColor]
        tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accentUIColor]
        tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accentUIColor]
        
        // Налаштовуємо колір іконок - завжди білі для темної теми
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
        tabBarAppearance.inlineLayoutAppearance.normal.iconColor = UIColor.white
        tabBarAppearance.compactInlineLayoutAppearance.normal.iconColor = UIColor.white
        
        // Налаштування кольорів вибраних іконок
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = accentUIColor
        tabBarAppearance.inlineLayoutAppearance.selected.iconColor = accentUIColor
        tabBarAppearance.compactInlineLayoutAppearance.selected.iconColor = accentUIColor
        
        // Применяем настройки для TabBar
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Настраиваем внешний вид NavigationBar
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(Color("topBacground"))
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: isDarkMode ? UIColor.white : UIColor.black]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: isDarkMode ? UIColor.white : UIColor.black]
        
        // Налаштовуємо кольори кнопок та елементів навігаційного бару
        let barButtonItemAppearance = UIBarButtonItemAppearance(style: .plain)
        barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: isDarkMode ? UIColor.white : UIColor.black]
        navigationBarAppearance.buttonAppearance = barButtonItemAppearance
        navigationBarAppearance.backButtonAppearance = barButtonItemAppearance
        
        // Застосовуємо колір до кнопок навігації
        UINavigationBar.appearance().tintColor = isDarkMode ? UIColor.white : UIColor.black
        
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
