//
//  UIThemeManager.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI
import UIKit

class UIThemeManager {
    static let shared = UIThemeManager()
    
    private init() {}
    
    // Функція для застосування налаштувань теми до UIKit компонентів
    func applyTheme(isDarkMode: Bool) {
        let colors = isDarkMode ? ThemeColors.dark : ThemeColors.light
        
        // Налаштування для TabBar
        configureTabBar(with: colors, isDarkMode: isDarkMode)
        
        // Налаштування для NavigationBar
        configureNavigationBar(with: colors)
        
        print("UIThemeManager: Applied theme, isDarkMode=\(isDarkMode)")
    }
    
    // Налаштування TabBar
    private func configureTabBar(with colors: ThemeColors, isDarkMode: Bool) {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = colors.tabBarBackground
        
        // Чітко встановлюємо саме ті кольори які потрібні для кожної теми
        let iconColor = isDarkMode ? UIColor.white : UIColor.black
        let textColor = isDarkMode ? UIColor.white : UIColor.black
        let accentColor = UIColor(Color.pink)
        
        // Налаштування кольорів тексту
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accentColor]
        tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accentColor]
        tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accentColor]
        
        // Налаштування кольорів іконок - примусово встановлюємо їх напряму
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = iconColor
        tabBarAppearance.inlineLayoutAppearance.normal.iconColor = iconColor
        tabBarAppearance.compactInlineLayoutAppearance.normal.iconColor = iconColor
        
        // Налаштування кольорів вибраних іконок
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = accentColor
        tabBarAppearance.inlineLayoutAppearance.selected.iconColor = accentColor
        tabBarAppearance.compactInlineLayoutAppearance.selected.iconColor = accentColor
        
        // Застосування налаштувань
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Примусово встановлюємо додаткові налаштування для підтримки різних версій iOS
        UITabBar.appearance().tintColor = accentColor
        UITabBar.appearance().unselectedItemTintColor = iconColor
        
        if isDarkMode {
            print("UIThemeManager: TabBar icons set to WHITE for dark mode")
        } else {
            print("UIThemeManager: TabBar icons set to BLACK for light mode")
        }
    }
    
    // Налаштування NavigationBar
    private func configureNavigationBar(with colors: ThemeColors) {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = colors.navigationBarBackground
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: colors.navigationBarText]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: colors.navigationBarText]
        
        // Налаштування кнопок
        let barButtonItemAppearance = UIBarButtonItemAppearance(style: .plain)
        barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: colors.navigationBarButtonText]
        navigationBarAppearance.buttonAppearance = barButtonItemAppearance
        navigationBarAppearance.backButtonAppearance = barButtonItemAppearance
        
        // Колір іконок навігації
        UINavigationBar.appearance().tintColor = colors.navigationBarTint
        
        // Застосування налаштувань
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
    }
} 