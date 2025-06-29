import Foundation
import SwiftUI

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    @Published var currentLanguage: String = Locale.current.languageCode ?? "en" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
            objectWillChange.send()
        }
    }
    
    var bundle: Bundle {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }
    
    func setLanguage(_ lang: String) {
        guard currentLanguage != lang else { return }
        print("[LocalizationManager] Changing language from \(currentLanguage) to \(lang)")
        currentLanguage = lang
    }
    
    func localizedString(forKey key: String) -> String {
        let value = bundle.localizedString(forKey: key, value: nil, table: nil)
        print("[LocalizationManager] key: \(key), lang: \(currentLanguage), value: \(value)")
        return value
    }
}

extension String {
    var localized: String {
        LocalizationManager.shared.localizedString(forKey: self)
    }
} 