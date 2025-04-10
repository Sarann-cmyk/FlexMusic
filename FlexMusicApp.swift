//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI

enum ThemeMode: Int, CaseIterable {
    case light = 0
    case dark = 1
    case system = 2
    
    var description: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gearshape.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .light: return .orange
        case .dark: return .purple
        case .system: return .gray
        }
    }
}

// Додамо нове перерахування для режимів фону плеєра
enum PlayerBackgroundMode: Int, CaseIterable {
    case staticGradient = 0
    case dynamic = 1
    
    var description: String {
        switch self {
        case .staticGradient: return "Static gradient"
        case .dynamic: return "Dynamic (based on cover)"
        }
    }
    
    var icon: String {
        switch self {
        case .staticGradient: return "rectangle.fill"
        case .dynamic: return "rectangle.on.rectangle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .staticGradient: return .blue
        case .dynamic: return .orange
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("themeMode") var themeMode: ThemeMode = .system {
        didSet {
            updateTheme()
        }
    }
    
    @AppStorage("playerBackgroundMode") var playerBackgroundMode: PlayerBackgroundMode = .staticGradient
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @Published var colorScheme: ColorScheme?
    
    init() {
        print("ThemeManager: Initializing...")
        
        // Спочатку скидаємо налаштування
        TabBarAppearance.reset()
        NavigationBarStyler.resetNavigationBarAppearance()
        
        // Визначаємо, чи темна тема активна
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark || themeMode == .dark
        
        // Застосовуємо відповідний стиль для навігаційного бару
        if isDarkMode {
            NavigationBarStyler.applyDarkTheme()
            print("ThemeManager: Applied dark navigation bar at startup")
        } else {
            NavigationBarStyler.applyLightTheme()
            print("ThemeManager: Applied light navigation bar at startup")
        }
        
        // Оновлюємо тему після застосування стилів
        updateTheme()
    }
    
    func updateTheme() {
        // Визначаємо чи темна тема активна
        switch themeMode {
        case .light:
            colorScheme = .light
            print("ThemeManager: Light theme selected")
            
            // Застосовуємо налаштування для світлої теми
            TabBarAppearance.configureForLightMode()
            NavigationBarStyler.applyLightTheme()
            
        case .dark:
            colorScheme = .dark
            print("ThemeManager: Dark theme selected")
            
            // Застосовуємо налаштування для темної теми
            TabBarAppearance.configureForDarkMode()
            NavigationBarStyler.applyDarkTheme()
            
        case .system:
            colorScheme = nil // використовувати системні налаштування
            let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
            print("ThemeManager: System theme selected (isDark: \(systemIsDark))")
            
            // Застосовуємо налаштування в залежності від системної теми
            if systemIsDark {
                TabBarAppearance.configureForDarkMode()
                NavigationBarStyler.applyDarkTheme()
            } else {
                TabBarAppearance.configureForLightMode()
                NavigationBarStyler.applyLightTheme()
            }
        }
        
        // Оновлюємо всі навігаційні елементи
        UIApplication.shared.windows.forEach { window in
            window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        }
        
        // Примусово оновлюємо всі навігаційні бари з невеликою затримкою
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NavigationBarStyler.forceRefreshAllNavigationBars()
            
            // Додатково запускаємо UIThemeManager для більш надійного застосування налаштувань
            let isDarkMode = self.themeMode == .dark || 
                (self.themeMode == .system && UITraitCollection.current.userInterfaceStyle == .dark)
            
            UIThemeManager.shared.applyTheme(isDarkMode: isDarkMode)
            
            print("ThemeManager: Theme update completed with additional refresh")
        }
    }
}

@main
struct FlexMusicApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    // Додаємо AppDelegate для налаштування на початку
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        return WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(themeManager.colorScheme)
                .environmentObject(themeManager)
                .onAppear {
                    // Використовуємо спрощений підхід 
                    print("FlexMusicApp: App appeared")
                    
                    // Оновлюємо тему (яка вже містить всі потрібні скидання і оновлення)
                    themeManager.updateTheme()
                }
                .onChange(of: UIApplication.shared.applicationState) { oldState, newState in
                    print("FlexMusicApp: App state changed from \(oldState) to \(newState)")
                    
                    if newState == .active {
                        // Додатково примусово оновлюємо тему при виході з фону
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            // Визначаємо поточну тему
                            let isDarkMode = themeManager.themeMode == .dark || 
                                (themeManager.themeMode == .system && UITraitCollection.current.userInterfaceStyle == .dark)
                            
                            print("FlexMusicApp: Reapplying theme on active, isDarkMode=\(isDarkMode)")
                            
                            // Застосовуємо відповідну тему
                            if isDarkMode {
                                NavigationBarStyler.applyDarkTheme()
                            } else {
                                NavigationBarStyler.applyLightTheme()
                            }
                            
                            // Примусово оновлюємо навігаційні бари
                            NavigationBarStyler.forceRefreshAllNavigationBars()
                        }
                    }
                }
        }
    }
}
