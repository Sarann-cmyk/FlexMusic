//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//



import SwiftUI
import UIKit

class NavigationBarStyler {
    static let shared = NavigationBarStyler()
    
    private init() {}
    
    func updateAppearance() {
        let appearance = UINavigationBarAppearance()
        
        // Налаштування фону
        appearance.backgroundColor = UIColor(named: "navigationBarBackground")
        
        // Налаштування кольору тексту
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(named: "navigationBarText") ?? .label
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(named: "navigationBarText") ?? .label
        ]
        
        // Налаштування кнопок
        appearance.buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(named: "accent") ?? .systemBlue
        ]
        
        // Налаштування для всіх станів
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Оновлюємо всі навігаційні бари
        refreshNavigationBars()
    }
    
    private func refreshNavigationBars() {
        // Отримуємо всі вікна
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let windows = windowScene?.windows ?? []
        
        // Оновлюємо навігаційні бари в кожному вікні
        for window in windows {
            if let rootViewController = window.rootViewController {
                updateNavigationBar(in: rootViewController)
            }
        }
    }
    
    private func updateNavigationBar(in viewController: UIViewController) {
        // Оновлюємо навігаційний бар поточного контролера
        if let navigationController = viewController.navigationController {
            navigationController.navigationBar.standardAppearance = UINavigationBar.appearance().standardAppearance
            navigationController.navigationBar.compactAppearance = UINavigationBar.appearance().compactAppearance
            navigationController.navigationBar.scrollEdgeAppearance = UINavigationBar.appearance().scrollEdgeAppearance
            
            // Оновлюємо всі видимі контролери в навігаційному стеку
            for vc in navigationController.viewControllers {
                vc.navigationItem.titleView?.setNeedsLayout()
                vc.navigationItem.titleView?.layoutIfNeeded()
            }
        }
        
        // Оновлюємо навігаційні бари дочірніх контролерів
        for child in viewController.children {
            updateNavigationBar(in: child)
        }
        
        // Якщо це таббар контролер, оновлюємо всі його вкладки
        if let tabBarController = viewController as? UITabBarController {
            for child in tabBarController.viewControllers ?? [] {
                updateNavigationBar(in: child)
            }
        }
    }
}
