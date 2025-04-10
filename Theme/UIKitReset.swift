//
//  UIKitReset.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import UIKit

/// Утиліта для примусового скидання і оновлення налаштувань UIKit
struct UIKitReset {
    
    /// Примусово скидає всі налаштування зовнішнього вигляду UIKit, щоб уникнути кешування та конфліктів
    static func resetAllAppearances() {
        print("UIKitReset: Resetting all UIKit appearances...")
        
        // Скидаємо налаштування TabBar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().unselectedItemTintColor = nil
        UITabBar.appearance().tintColor = nil
        
        // Скидаємо налаштування NavigationBar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        // Примусово скидаємо всі кешовані налаштування
        DispatchQueue.main.async {
            let windows = UIApplication.shared.windows
            windows.forEach { window in
                window.subviews.forEach { view in
                    view.removeFromSuperview()
                    window.addSubview(view)
                }
            }
        }
        
        print("UIKitReset: All UIKit appearances have been reset")
    }
} 