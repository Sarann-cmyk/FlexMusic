//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI
import CoreData

@main
struct FlexMusicApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    init() {
        // Налаштування навігаційної панелі
        NavigationBarStyler.shared.updateAppearance()
        // Налаштування інструментальної панелі
        ToolbarStyler.shared.updateAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(themeManager.colorScheme)
                .environmentObject(themeManager)
                .environmentObject(localizationManager)
        }
    }
}

