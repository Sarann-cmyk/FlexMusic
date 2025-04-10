import SwiftUI

enum Tab {
    case library
    case player
    case settings
}

class TabManager: ObservableObject {
    @Published var selectedTab: Tab = .library
} 