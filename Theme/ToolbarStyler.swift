//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI
import UIKit

class ToolbarStyler {
    static let shared = ToolbarStyler()
    
    private init() {}
    
    func updateAppearance() {
        // Налаштування TabBar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = UIColor(named: "tabBarBackground")
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(named: "textSecondary")
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(named: "tabBarTint")
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(named: "textSecondary") ?? .gray
        ]
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(named: "tabBarTint") ?? .systemBlue
        ]
        
        // Налаштування Toolbar
        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.backgroundColor = UIColor(named: "tabBarBackground")
        toolbarAppearance.buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(named: "tabBarTint") ?? .systemBlue
        ]
        
        // Застосовуємо налаштування для всіх станів
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        UIToolbar.appearance().standardAppearance = toolbarAppearance
        UIToolbar.appearance().scrollEdgeAppearance = toolbarAppearance
        
        // Оновлюємо всі інструментальні панелі
        refreshToolbars()
    }
    
    private func refreshToolbars() {
        // Отримуємо всі вікна
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let windows = windowScene?.windows ?? []
        
        // Оновлюємо інструментальні панелі в кожному вікні
        for window in windows {
            if let rootViewController = window.rootViewController {
                updateToolbars(in: rootViewController)
            }
        }
    }
    
    private func updateToolbars(in viewController: UIViewController) {
        // Оновлюємо TabBar
        if let tabBarController = viewController as? UITabBarController {
            tabBarController.tabBar.standardAppearance = UITabBar.appearance().standardAppearance
            tabBarController.tabBar.scrollEdgeAppearance = UITabBar.appearance().scrollEdgeAppearance
        }
        
        // Оновлюємо Toolbar
        if let toolbar = viewController.navigationController?.toolbar {
            toolbar.standardAppearance = UIToolbar.appearance().standardAppearance
            toolbar.scrollEdgeAppearance = UIToolbar.appearance().scrollEdgeAppearance
        }
        
        // Оновлюємо інструментальні панелі дочірніх контролерів
        for child in viewController.children {
            updateToolbars(in: child)
        }
    }
} 
