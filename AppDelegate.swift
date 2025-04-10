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
        } else {
            TabBarAppearance.configureForLightMode()
        }
        
        print("AppDelegate: App started with isDarkMode=\(isDarkMode)")
        
        return true
    }
} 