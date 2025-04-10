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
        // Виконаємо updateTheme після короткої затримки, щоб переконатися, що UI вже ініціалізований
        print("ThemeManager: Initializing...")
        updateTheme()
        
        // Додаткове оновлення через 1 секунду для стабільності
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Повний скид налаштувань перед повторним застосуванням
            UIKitReset.resetAllAppearances()
            self.updateTheme()
            print("ThemeManager: Delayed theme update applied after reset")
        }
    }
    
    func updateTheme() {
        // Скидаємо всі попередні налаштування для чистого старту
        TabBarAppearance.reset()
        
        // Визначаємо чи темна тема активна
        let isDarkModeActive: Bool
        
        switch themeMode {
        case .light:
            colorScheme = .light
            isDarkModeActive = false
            print("ThemeManager: Light theme activated")
            TabBarAppearance.configureForLightMode()
        case .dark:
            colorScheme = .dark
            isDarkModeActive = true
            print("ThemeManager: Dark theme activated")
            TabBarAppearance.configureForDarkMode()
        case .system:
            colorScheme = nil // використовувати системні налаштування
            let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
            isDarkModeActive = systemIsDark
            print("ThemeManager: System theme activated (isDark: \(systemIsDark))")
            
            if systemIsDark {
                TabBarAppearance.configureForDarkMode()
            } else {
                TabBarAppearance.configureForLightMode()
            }
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
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(themeManager.colorScheme)
                .environmentObject(themeManager)
                .onAppear {
                    // Додаткове оновлення теми при запуску додатку
                    print("FlexMusicApp: App appeared, updating theme...")
                    // Скидаємо налаштування перед застосуванням
                    UIKitReset.resetAllAppearances()
                    themeManager.updateTheme()
                }
        }
    }
}
