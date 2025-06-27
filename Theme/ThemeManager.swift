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

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("themeMode") var themeMode: ThemeMode = .system {
        didSet {
            updateTheme()
            updateAppearance()
        }
    }
    
    @Published var colorScheme: ColorScheme?
    
    var isDarkMode: Bool {
        switch themeMode {
        case .light:
            return false
        case .dark:
            return true
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    private init() {
        updateTheme()
    }
    
    func updateTheme() {
        switch themeMode {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = nil // використовувати системні налаштування
        }
    }
    
    private func saveThemeMode() {
        let themeString: String
        switch themeMode {
        case .light:
            themeString = "light"
        case .dark:
            themeString = "dark"
        case .system:
            themeString = "system"
        }
        UserDefaults.standard.set(themeString, forKey: "ThemeMode")
    }
    
    func updateAppearance() {
        // Отримуємо всі вікна один раз
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let windows = windowScene?.windows ?? []
        
        // Створюємо всі appearance об'єкти
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = UIColor(named: "navigationBarBackground")
        navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "navigationBarText") ?? .label]
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "navigationBarText") ?? .label]
        
        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.configureWithOpaqueBackground()
        toolbarAppearance.backgroundColor = UIColor(named: "tabBarBackground")
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(named: "tabBarBackground")
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(named: "textSecondary") ?? .gray]
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(named: "tabBarTint") ?? .systemBlue]
        
        // Оновлюємо глобальні appearance
        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        
        UIToolbar.appearance().standardAppearance = toolbarAppearance
        UIToolbar.appearance().scrollEdgeAppearance = toolbarAppearance
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Оновлюємо всі вікна та контролери
        DispatchQueue.main.async {
            for window in windows {
                // Оновлюємо стиль вікна
                window.overrideUserInterfaceStyle = self.themeMode == .system ? .unspecified :
                    self.themeMode == .dark ? .dark : .light
                
                // Оновлюємо кореневий контролер
                if let rootViewController = window.rootViewController {
                    // Оновлюємо навігаційний контролер
                    if let navigationController = rootViewController.navigationController {
                        navigationController.navigationBar.standardAppearance = navigationAppearance
                        navigationController.navigationBar.compactAppearance = navigationAppearance
                        navigationController.navigationBar.scrollEdgeAppearance = navigationAppearance
                        navigationController.navigationBar.setNeedsLayout()
                        navigationController.navigationBar.layoutIfNeeded()
                    }
                    
                    // Оновлюємо таббар контролер
                    if let tabBarController = rootViewController as? UITabBarController {
                        tabBarController.tabBar.standardAppearance = tabBarAppearance
                        tabBarController.tabBar.scrollEdgeAppearance = tabBarAppearance
                        tabBarController.tabBar.setNeedsLayout()
                        tabBarController.tabBar.layoutIfNeeded()
                    }
                    
                    // Оновлюємо статус бар
                    rootViewController.setNeedsStatusBarAppearanceUpdate()
                }
            }
            
            // Сповіщаємо про зміну кольорів
            NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChange"), object: nil)
        }
    }
    
    // MARK: - Color Access
    
    var backgroundColor: Color {
        Color("background")
    }
    
    var textColor: Color {
        Color("textPrimary")
    }
    
    var secondaryTextColor: Color {
        Color("textSecondary")
    }
    
    var accentColor: Color {
        Color("accent")
    }
    
    var playerIconColor: Color {
        Color("buttonText")
    }
    
    var progressBarColor: Color {
        isDarkMode ? Color("textPrimary") : Color("textSecondary")
    }
    
    var trackTitleColor: Color {
        Color("textPrimary")
    }
    
    var artistNameColor: Color {
        Color("textSecondary")
    }
    
    var buttonBackgroundColor: Color {
        Color("buttonBackground")
    }
    
    var tabBarBackgroundColor: Color {
        Color("tabBarBackground")
    }
    
    var tabBarTintColor: Color {
        Color("tabBarTint")
    }
    
    var navigationBarBackgroundColor: Color {
        Color("navigationBarBackground")
    }
    
    var navigationBarTextColor: Color {
        Color("navigationBarText")
    }
} 
