//
//  TabBarAppearance.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI
import UIKit

struct TabBarAppearance {
    static func configureForLightMode() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color("bottomBacground"))
        
        // Створюємо базові налаштування для елементів
        let itemAppearance = UITabBarItemAppearance()
        
        // Колір невибраних іконок та тексту (ТЕМНИЙ для світлої теми, але трохи прозоріший)
        itemAppearance.normal.iconColor = UIColor.black.withAlphaComponent(0.65)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.black.withAlphaComponent(0.65)]
        
        // Колір вибраних іконок та тексту (рожевий)
        itemAppearance.selected.iconColor = UIColor.systemPink
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemPink]
        
        // Застосовуємо налаштування до всіх типів макетів
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        // Застосовуємо налаштування до UITabBar
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Додаткові прямі налаштування
        UITabBar.appearance().unselectedItemTintColor = UIColor.black.withAlphaComponent(0.65)
        UITabBar.appearance().tintColor = .systemPink
        
        print("TabBarAppearance: Configured for LIGHT mode - SOFTER BLACK icons")
    }
    
    static func configureForDarkMode() {
        // Скидаємо попередні налаштування для уникнення кешування
        reset()
        
        // Створюємо новий appearance для темної теми з мінімальною помітністю
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Встановлюємо чорний фон для основи таб-бару
        let backgroundColor = UIColor.black
        appearance.backgroundColor = backgroundColor
        
        // Додаємо сіру полоску зверху для делікатного розділення
        // це аналогічно до того, що використовується в NavigationBarStyler
        appearance.shadowColor = UIColor.darkGray.withAlphaComponent(0.3)
        appearance.shadowImage = createSinglePixelImage(color: UIColor.darkGray.withAlphaComponent(0.3))
        
        // Створюємо нові налаштування для елементів
        let itemAppearance = UITabBarItemAppearance()
        
        // Примусово встановлюємо БІЛИЙ колір для іконок та тексту
        // Використання .white замість .light для кращої видимості
        itemAppearance.normal.iconColor = UIColor.white
        itemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        // Встановлюємо яскраво-рожевий колір для вибраних елементів
        let accentColor = UIColor.systemPink
        itemAppearance.selected.iconColor = accentColor
        itemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: accentColor]
        
        // Застосовуємо налаштування до всіх типів макетів
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        // Застосовуємо налаштування до UITabBar
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Додаткові налаштування для iOS 13+
        UITabBar.appearance().unselectedItemTintColor = UIColor.white
        UITabBar.appearance().tintColor = accentColor
        
        // iOS 17+ додаткові налаштування для стабільності вигляду
        if #available(iOS 17.0, *) {
            UITabBar.appearance().barStyle = .black
            
            // Примусово встановити чіткі межі між таббаром та контентом
            UITabBar.appearance().layer.borderWidth = 0.5
            UITabBar.appearance().layer.borderColor = UIColor.darkGray.withAlphaComponent(0.3).cgColor
            
            // Додатково переконуємось, що фон точно чорний
            UITabBar.appearance().barTintColor = .black
        }
        
        print("TabBarAppearance: Configured for DARK mode - WHITE icons (enhanced)")
    }
    
    static func reset() {
        // Скидаємо всі налаштування
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = nil
        
        print("TabBarAppearance: Reset all settings")
    }
    
    // Допоміжна функція для створення одиночного пікселя для розділової лінії
    private static func createSinglePixelImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
} 