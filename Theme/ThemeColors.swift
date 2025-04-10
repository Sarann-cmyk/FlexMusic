//
//  ThemeColors.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//

import SwiftUI
import UIKit

// Структура, що містить всі кольори для теми
struct ThemeColors {
    // Загальні кольори інтерфейсу
    let textPrimary: Color
    let textSecondary: Color
    let background: Color
    let topBackground: Color
    let bottomBackground: Color
    
    // TabBar кольори
    let tabBarBackground: UIColor
    let tabBarIconsNormal: UIColor
    let tabBarIconsSelected: UIColor
    let tabBarTextNormal: UIColor
    let tabBarTextSelected: UIColor
    
    // NavigationBar кольори
    let navigationBarBackground: UIColor
    let navigationBarText: UIColor
    let navigationBarButtonText: UIColor
    let navigationBarTint: UIColor
    
    // Світла тема
    static let light = ThemeColors(
        textPrimary: Color.black.opacity(0.8),
        textSecondary: Color("textSecondary"),
        background: Color.white,
        topBackground: Color("topBacground"),
        bottomBackground: Color("bottomBacground"),
        
        // TabBar
        tabBarBackground: UIColor(Color("bottomBacground")),
        tabBarIconsNormal: UIColor.black.withAlphaComponent(0.65),
        tabBarIconsSelected: UIColor(Color.pink),
        tabBarTextNormal: UIColor.black.withAlphaComponent(0.65),
        tabBarTextSelected: UIColor(Color.pink),
        
        // NavigationBar
        navigationBarBackground: UIColor(Color("topBacground")),
        navigationBarText: UIColor.black.withAlphaComponent(0.8),
        navigationBarButtonText: UIColor.black.withAlphaComponent(0.8),
        navigationBarTint: UIColor.black.withAlphaComponent(0.8)
    )
    
    // Темна тема
    static let dark = ThemeColors(
        textPrimary: Color.white,
        textSecondary: Color("textSecondary"),
        background: Color.black,
        topBackground: Color("topBacground"),
        bottomBackground: Color("bottomBacground"),
        
        // TabBar
        tabBarBackground: UIColor(Color("bottomBacground")),
        tabBarIconsNormal: UIColor.white,
        tabBarIconsSelected: UIColor(Color.pink),
        tabBarTextNormal: UIColor.white,
        tabBarTextSelected: UIColor(Color.pink),
        
        // NavigationBar
        navigationBarBackground: UIColor(Color("bottomBacground")),
        navigationBarText: UIColor.white,
        navigationBarButtonText: UIColor.white,
        navigationBarTint: UIColor.white
    )
} 