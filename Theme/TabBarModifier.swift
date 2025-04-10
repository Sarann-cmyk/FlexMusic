//
//  TabBarModifier.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI

struct TabBarModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                let isDarkMode = colorScheme == .dark
                
                // Налаштування для оновлення TabBar
                let appearance = UITabBarAppearance()
                
                if isDarkMode {
                    // Мінімальна помітність для темної теми
                    appearance.configureWithTransparentBackground()
                    
                    // Видаляємо ефект розмиття, щоб не було сірого відтінку
                    appearance.backgroundEffect = nil
                    
                    // Використовуємо чистий чорний колір з високою прозорістю
                    appearance.backgroundColor = UIColor.black.withAlphaComponent(0.2)
                    
                    // Додаємо тонку верхню межу для делікатного розділення
                    appearance.shadowColor = UIColor.black.withAlphaComponent(0.3)
                } else {
                    appearance.configureWithOpaqueBackground()
                    appearance.backgroundColor = UIColor(backgroundColor)
                }
                
                let itemAppearance = UITabBarItemAppearance()
                
                // Колір невибраних іконок та тексту
                itemAppearance.normal.iconColor = isDarkMode ? .white : .black
                itemAppearance.normal.titleTextAttributes = [
                    .foregroundColor: isDarkMode ? UIColor.white : UIColor.black
                ]
                
                // Колір вибраних іконок та тексту 
                itemAppearance.selected.iconColor = UIColor.systemPink
                itemAppearance.selected.titleTextAttributes = [
                    .foregroundColor: UIColor.systemPink
                ]
                
                // Застосовуємо налаштування до всіх макетів
                appearance.stackedLayoutAppearance = itemAppearance
                appearance.inlineLayoutAppearance = itemAppearance
                appearance.compactInlineLayoutAppearance = itemAppearance
                
                // Застосовуємо налаштування до UITabBar
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
                
                // Додаткові безпосередні налаштування
                UITabBar.appearance().unselectedItemTintColor = isDarkMode ? .white : .black
                UITabBar.appearance().tintColor = .systemPink
                
                print("TabBarModifier: Applied, isDarkMode=\(isDarkMode)")
            }
    }
}

extension View {
    func customTabBar(backgroundColor: Color) -> some View {
        self.modifier(TabBarModifier(backgroundColor: backgroundColor))
    }
} 