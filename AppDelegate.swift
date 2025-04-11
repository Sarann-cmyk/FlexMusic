//
//  AppDelegate.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("AppDelegate: App starting...")
        
        // Визначаємо поточну тему через ThemeManager
        let themeManager = ThemeManager.shared
        let isDarkMode = themeManager.themeMode == .dark
        
        print("AppDelegate: Current app theme is \(isDarkMode ? "DARK" : "LIGHT")")
        
        // Застосовуємо відповідні налаштування
        if isDarkMode {
            TabBarAppearance.configureForDarkMode()
            NavigationBarStyler.applyDarkTheme()
        } else {
            TabBarAppearance.configureForLightMode()
            NavigationBarStyler.applyLightTheme()
        }
        
        // Примусово оновлюємо всі навігаційні бари
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NavigationBarStyler.forceRefreshAllNavigationBars()
        }
        
        return true
    }
    
    // Додаємо методи для обробки відновлення додатка з фону
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("AppDelegate: App became active")
        
        // Визначаємо і застосовуємо поточну тему через ThemeManager
        let themeManager = ThemeManager.shared
        let isDarkMode = themeManager.themeMode == .dark
        
        print("AppDelegate: Reapplying theme on active, isDarkMode=\(isDarkMode)")
        
        // Спочатку скидаємо налаштування
        NavigationBarStyler.resetNavigationBarAppearance()
        
        if isDarkMode {
            NavigationBarStyler.applyDarkTheme()
            TabBarAppearance.configureForDarkMode()
        } else {
            NavigationBarStyler.applyLightTheme()
            TabBarAppearance.configureForLightMode()
        }
        
        // Примусово оновлюємо всі навігаційні бари
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NavigationBarStyler.forceRefreshAllNavigationBars()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("AppDelegate: App will enter foreground")
        
        // Примусово скидаємо і оновлюємо налаштування UIKit
        UIKitReset.resetAllAppearances()
        
        // Додатково примусово оновлюємо тему через ThemeManager
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ThemeManager.shared.updateTheme()
        }
    }
} 