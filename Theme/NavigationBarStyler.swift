//
//  NavigationBarStyler.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import UIKit
import SwiftUI

/// Утиліта для безпосереднього стилізування NavigationBar
struct NavigationBarStyler {
    
    /// Застосувати стиль для темної теми
    static func applyDarkTheme() {
        let darkColor = UIColor.black
        
        // Налаштування для основних стилів UIKit
        UINavigationBar.appearance().barStyle = .black
        UINavigationBar.appearance().barTintColor = darkColor
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().isTranslucent = true
                
        // Створюємо новий appearance спеціально для темної теми
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = darkColor
        
        // Налаштовуємо стиль тексту - колір та атрибути
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 17)
        ]
        
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 34)
        ]
        
        // Налаштування кнопок
        let barButtonItemAppearance = UIBarButtonItemAppearance(style: .plain)
        barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        barButtonItemAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.3)]
        barButtonItemAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.white]
        barButtonItemAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationBarAppearance.buttonAppearance = barButtonItemAppearance
        navigationBarAppearance.backButtonAppearance = barButtonItemAppearance
        
        // Застосовуємо налаштування напряму через UIKit
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        
        // Застосовуємо до всіх активних навігаційних контролерів
        applyToAllActiveNavigationControllers(appearance: navigationBarAppearance, barTintColor: darkColor, tintColor: UIColor.white)
        
        // Примусове оновлення навігаційного бару в усіх контролерах
        forceRefreshAllNavigationBars()
        
        print("NavigationBarStyler: Applied DARK style for dark mode")
    }
    
    /// Примусово застосовує стиль до всіх активних навігаційних контролерів
    private static func applyToAllActiveNavigationControllers(appearance: UINavigationBarAppearance, barTintColor: UIColor, tintColor: UIColor = UIColor.white) {
        // Шукаємо всі вікна в додатку
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            // Рекурсивно шукаємо всі навігаційні контролери
            findAndUpdateNavigationBars(in: window.rootViewController, appearance: appearance, barTintColor: barTintColor, tintColor: tintColor)
        }
    }
    
    /// Рекурсивно шукає всі навігаційні контролери і оновлює їх стилі
    private static func findAndUpdateNavigationBars(in viewController: UIViewController?, appearance: UINavigationBarAppearance, barTintColor: UIColor, tintColor: UIColor = UIColor.white) {
        guard let viewController = viewController else { return }
        
        // Якщо це навігаційний контролер, оновлюємо його навбар
        if let navigationController = viewController as? UINavigationController {
            navigationController.navigationBar.standardAppearance = appearance
            navigationController.navigationBar.scrollEdgeAppearance = appearance
            navigationController.navigationBar.compactAppearance = appearance
            
            // Не змінюємо прозорість тут, бо вона вже встановлена в applyDarkTheme/applyLightTheme
            // navigationController.navigationBar.isTranslucent = tintColor == UIColor.white ? false : true
            
            // Примусово очищаємо та встановлюємо потрібні кольори
            navigationController.navigationBar.barTintColor = barTintColor
            navigationController.navigationBar.tintColor = tintColor
        }
        
        // Перевіряємо презентований контролер
        if let presented = viewController.presentedViewController {
            findAndUpdateNavigationBars(in: presented, appearance: appearance, barTintColor: barTintColor, tintColor: tintColor)
        }
        
        // Перевіряємо дочірні контролери
        for child in viewController.children {
            findAndUpdateNavigationBars(in: child, appearance: appearance, barTintColor: barTintColor, tintColor: tintColor)
        }
    }
    
    /// Скидає всі налаштування навігаційного бару до початкових значень
    static func resetNavigationBarAppearance() {
        let emptyAppearance = UINavigationBarAppearance()
        emptyAppearance.configureWithDefaultBackground()
        
        // Очищення глобальних налаштувань
        UINavigationBar.appearance().standardAppearance = emptyAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = emptyAppearance
        UINavigationBar.appearance().compactAppearance = emptyAppearance
        
        // Додатково скидаємо tintColor, щоб уникнути залишення цього кольору
        UINavigationBar.appearance().tintColor = nil
        
        // Скидаємо властивість translucent для більш чистого старту
        UINavigationBar.appearance().isTranslucent = true
        
        // Скидаємо barTintColor
        UINavigationBar.appearance().barTintColor = nil
        
        // Примусово очищаємо всі індивідуальні навігаційні контролери в додатку
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            resetAllNavigationBars(in: window.rootViewController)
        }
        
        print("NavigationBarStyler: Reset all navigation bar appearances")
    }
    
    /// Рекурсивно скидає налаштування всіх навігаційних контролерів
    private static func resetAllNavigationBars(in viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        if let navigationController = viewController as? UINavigationController {
            let emptyAppearance = UINavigationBarAppearance()
            emptyAppearance.configureWithDefaultBackground()
            
            navigationController.navigationBar.standardAppearance = emptyAppearance
            navigationController.navigationBar.scrollEdgeAppearance = emptyAppearance
            navigationController.navigationBar.compactAppearance = emptyAppearance
            
            // Додаткові скидання для уникнення кешованих значень
            navigationController.navigationBar.tintColor = nil
            navigationController.navigationBar.barTintColor = nil
            navigationController.navigationBar.isTranslucent = true
            
            // Примусове оновлення
            navigationController.navigationBar.layoutIfNeeded()
        }
        
        // Перевіряємо презентований контролер
        if let presented = viewController.presentedViewController {
            resetAllNavigationBars(in: presented)
        }
        
        // Перевіряємо дочірні контролери
        for child in viewController.children {
            resetAllNavigationBars(in: child)
        }
    }
    
    /// Застосувати стиль для світлої теми
    static func applyLightTheme() {
        let lightColor = UIColor(Color("topBacground"))
        
        // Налаштування для основних стилів UIKit
        UINavigationBar.appearance().barStyle = .default
        UINavigationBar.appearance().barTintColor = lightColor
        UINavigationBar.appearance().tintColor = UIColor.black.withAlphaComponent(0.8)
        UINavigationBar.appearance().isTranslucent = true
        
        // Створюємо новий appearance спеціально для світлої теми
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = lightColor
        
        // Налаштовуємо тонку тінь
        navigationBarAppearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        // Налаштовуємо стиль тексту - колір та атрибути
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.black.withAlphaComponent(0.8),
            .font: UIFont.boldSystemFont(ofSize: 17)
        ]
        
        navigationBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.black.withAlphaComponent(0.8),
            .font: UIFont.boldSystemFont(ofSize: 34)
        ]
        
        // Налаштування кнопок
        let barButtonItemAppearance = UIBarButtonItemAppearance(style: .plain)
        barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.black.withAlphaComponent(0.8)]
        barButtonItemAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.black.withAlphaComponent(0.3)]
        barButtonItemAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.black.withAlphaComponent(0.9)]
        barButtonItemAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.black.withAlphaComponent(0.9)]
        
        navigationBarAppearance.buttonAppearance = barButtonItemAppearance
        navigationBarAppearance.backButtonAppearance = barButtonItemAppearance
        
        // Застосовуємо налаштування напряму через UIKit
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        
        // Застосовуємо до всіх активних навігаційних контролерів
        applyToAllActiveNavigationControllers(appearance: navigationBarAppearance, barTintColor: lightColor, tintColor: UIColor.black.withAlphaComponent(0.8))
        
        // Примусове оновлення навігаційного бару в усіх контролерах
        forceRefreshAllNavigationBars()
        
        print("NavigationBarStyler: Applied LIGHT style for light mode")
    }
    
    /// Застосувати стиль в залежності від поточної теми системи
    static func applyCurrentThemeStyle() {
        // Спочатку скидаємо налаштування
        resetNavigationBarAppearance()
        
        // Застосовуємо стиль відповідно до системної теми
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        if isDarkMode {
            applyDarkTheme()
        } else {
            applyLightTheme()
        }
    }
    
    /// Примусово оновлює всі навігаційні бари в додатку
    static func forceRefreshAllNavigationBars() {
        // Знаходимо всі вікна в додатку
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                // Примусове оновлення ієрархії вікна
                window.setNeedsLayout()
                window.layoutIfNeeded()
                
                // Оновлюємо всі навігаційні контролери в цьому вікні
                refreshNavControllersInHierarchy(window.rootViewController)
            }
        }
        
        print("NavigationBarStyler: Force refreshed all navigation bars")
    }
    
    /// Рекурсивно оновлює всі навігаційні контролери в ієрархії
    private static func refreshNavControllersInHierarchy(_ viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        // Якщо це навігаційний контролер, оновлюємо його
        if let navigationController = viewController as? UINavigationController {
            // Оновлюємо властивість прозорості, що змушує бар перемалюватись
            let isTranslucent = navigationController.navigationBar.isTranslucent
            navigationController.navigationBar.isTranslucent = !isTranslucent
            navigationController.navigationBar.isTranslucent = isTranslucent
            
            // Примусове перемалювування
            navigationController.navigationBar.setNeedsLayout()
            navigationController.navigationBar.layoutIfNeeded()
            navigationController.view.setNeedsLayout()
            navigationController.view.layoutIfNeeded()
        }
        
        // Перевіряємо презентований контролер
        if let presented = viewController.presentedViewController {
            refreshNavControllersInHierarchy(presented)
        }
        
        // Перевіряємо дочірні контролери
        for child in viewController.children {
            refreshNavControllersInHierarchy(child)
        }
    }
} 