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
    @State private var selectedTab = 1
    
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
            
            PlaylistView()
                .tabItem {
                    Label("Playlists", systemImage: "music.note.house.fill")
                }
                .tag(3)
        }
        .accentColor(.white)
        .onAppear {
            // Настраиваем внешний вид TabBar
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(Color("bottomBacground"))
            
            // Настраиваем цвет текста и иконок TabBar
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
            tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
            tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
            tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
            tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            // Применяем настройки для TabBar
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            
            // Настраиваем внешний вид NavigationBar
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.backgroundColor = UIColor(Color("topBacground"))
            navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            // Применяем настройки для NavigationBar
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
            UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
