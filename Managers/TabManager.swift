//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI

enum Tab {
    case library
    case player
    case settings
}

class TabManager: ObservableObject {
    @Published var selectedTab: Tab = .library
} 
