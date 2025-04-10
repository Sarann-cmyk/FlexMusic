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
        
        // Колір невибраних іконок та тексту (ТЕМНИЙ для світлої теми)
        itemAppearance.normal.iconColor = .black
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.black]
        
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
        UITabBar.appearance().unselectedItemTintColor = .black
        UITabBar.appearance().tintColor = .systemPink
        
        print("TabBarAppearance: Configured for LIGHT mode - BLACK icons")
    }
    
    static func configureForDarkMode() {
        // Скидаємо попередні налаштування для уникнення кешування
        reset()
        
        // Створюємо новий appearance для темної теми
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color("bottomBacground"))
        
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
} 