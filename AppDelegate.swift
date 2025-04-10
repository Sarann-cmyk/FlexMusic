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
        
        // Визначаємо поточну тему
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        
        // Застосовуємо відповідні налаштування TabBar
        if isDarkMode {
            TabBarAppearance.configureForDarkMode()
            // Застосовуємо спеціальні налаштування для навігаційного бару
            NavigationBarStyler.applyDarkTheme()
        } else {
            TabBarAppearance.configureForLightMode()
            // Застосовуємо спеціальні налаштування для навігаційного бару
            NavigationBarStyler.applyLightTheme()
        }
        
        print("AppDelegate: App started with isDarkMode=\(isDarkMode)")
        
        return true
    }
    
    // Додаємо методи для обробки відновлення додатка з фону
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("AppDelegate: App became active")
        
        // Визначаємо і застосовуємо поточну тему
        let themeManager = ThemeManager.shared
        let isDarkModeSelected = themeManager.themeMode == .dark || 
            (themeManager.themeMode == .system && UITraitCollection.current.userInterfaceStyle == .dark)
        
        if isDarkModeSelected {
            NavigationBarStyler.applyDarkTheme()
            TabBarAppearance.configureForDarkMode()
            print("AppDelegate: Reapplied DARK theme on app active")
        } else {
            NavigationBarStyler.applyLightTheme()
            TabBarAppearance.configureForLightMode()
            print("AppDelegate: Reapplied LIGHT theme on app active")
        }
        
        // Примусово оновлюємо всі навігаційні бари
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NavigationBarStyler.forceRefreshAllNavigationBars()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("AppDelegate: App will enter foreground")
        
        // Примусово скидаємо і оновлюємо налаштування UIKit
        UIKitReset.resetAllAppearances()
        
        // Додатково примусово оновлюємо тему через ThemeManager
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            ThemeManager.shared.updateTheme()
        }
    }
} 