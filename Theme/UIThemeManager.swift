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
        configureNavigationBar(with: colors, isDarkMode: isDarkMode)
        
        // Додаткове примусове налаштування для NavigationBar в темній темі
        if isDarkMode {
            forceBlackNavigationBar()
        }
        
        print("UIThemeManager: Applied theme, isDarkMode=\(isDarkMode)")
    }
    
    // Налаштування TabBar
    private func configureTabBar(with colors: ThemeColors, isDarkMode: Bool) {
        let tabBarAppearance = UITabBarAppearance()
        
        if isDarkMode {
            // Непрозорий чорний фон з сірою верхньою межею
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = .black
            tabBarAppearance.shadowColor = UIColor.darkGray.withAlphaComponent(0.3)
            tabBarAppearance.shadowImage = createSinglePixelImage(color: UIColor.darkGray.withAlphaComponent(0.3))
            
            // Додатково встановлюємо BorderWidth для більш чіткого вигляду на iOS 17+
            if #available(iOS 17.0, *) {
                UITabBar.appearance().layer.borderWidth = 0.5
                UITabBar.appearance().layer.borderColor = UIColor.darkGray.withAlphaComponent(0.3).cgColor
                UITabBar.appearance().barTintColor = .black
            }
        } else {
            // Світла тема - білий фон
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = colors.tabBarBackground
        }
        
        // Налаштування для різних станів табів
        let itemAppearance = UITabBarItemAppearance()
        
        // Нормальний стан
        itemAppearance.normal.iconColor = isDarkMode ? .white : UIColor.black.withAlphaComponent(0.65)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: isDarkMode ? UIColor.white : UIColor.black.withAlphaComponent(0.65)]
        
        // Вибраний стан
        itemAppearance.selected.iconColor = colors.tabBarIconsSelected
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: colors.tabBarTextSelected]
        
        // Застосовуємо налаштування до всіх типів макетів
        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        tabBarAppearance.inlineLayoutAppearance = itemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = itemAppearance
        
        // Застосовуємо налаштування до UITabBar
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Встановлюємо кольори для елементів напряму
        UITabBar.appearance().unselectedItemTintColor = isDarkMode ? .white : UIColor.black.withAlphaComponent(0.65)
        UITabBar.appearance().tintColor = colors.tabBarIconsSelected
    }
    
    // Допоміжна функція для створення одиночного пікселя
    private func createSinglePixelImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    // Налаштування NavigationBar
    private func configureNavigationBar(with colors: ThemeColors, isDarkMode: Bool) {
        let navigationBarAppearance = UINavigationBarAppearance()
        
        if isDarkMode {
            // Для темної теми робимо чистий чорний фон
            navigationBarAppearance.configureWithOpaqueBackground()
            
            // Видаляємо ефект розмиття
            navigationBarAppearance.backgroundEffect = nil
            
            // Використовуємо повністю чорний колір без прозорості
            navigationBarAppearance.backgroundColor = UIColor.black
            
            // Темна тінь для чіткішого розділення
            navigationBarAppearance.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
            navigationBarAppearance.shadowImage = UIImage()
        } else {
            // Непрозорий фон для світлої теми
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.backgroundColor = colors.navigationBarBackground
        }
        
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
        
        // Додаткові прямі налаштування для прозорості
        if isDarkMode {
            // Встановлюємо true для узгодження з NavigationBarStyler
            UINavigationBar.appearance().isTranslucent = true
            UINavigationBar.appearance().barTintColor = UIColor.black
        } else {
            UINavigationBar.appearance().isTranslucent = true
            UINavigationBar.appearance().barTintColor = colors.navigationBarBackground
        }
    }
    
    // Примусове налаштування чорного навігаційного бару
    private func forceBlackNavigationBar() {
        // Використовуємо спеціалізований стилізатор для навігаційного бару
        NavigationBarStyler.applyDarkTheme()
    }
} 