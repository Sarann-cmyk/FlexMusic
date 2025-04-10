//
//  SettingsView.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 23.03.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black.opacity(0.75)
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
    }
    
    var overlayStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)
    }
    
    var backgroundFillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)
    }
    
    // Функції для створення кнопок теми
    @ViewBuilder
    private func themeButton(
        mode: ThemeMode,
        icon: String,
        title: String,
        iconColor: Color
    ) -> some View {
        Button {
            // Обробка натискання кнопки в окремому блоці для уникнення проблем з кешуванням
            handleThemeButtonPress(mode: mode)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(themeManager.themeMode == mode ? iconColor : textColor)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.themeMode == mode ? textColor : secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.themeMode == mode ? backgroundFillColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(overlayStrokeColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Окрема функція для обробки зміни теми з додатковими очищеннями і затримками
    private func handleThemeButtonPress(mode: ThemeMode) {
        // Встановлюємо нову тему (це викличе оновлення через didSet у ThemeManager)
        themeManager.themeMode = mode
        
        // Додаткове примусове застосування з невеликою затримкою
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Застосовуємо потрібний стиль напряму
            switch mode {
            case .light:
                NavigationBarStyler.applyLightTheme()
            case .dark:
                NavigationBarStyler.applyDarkTheme()
            case .system:
                let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
                if isDarkMode {
                    NavigationBarStyler.applyDarkTheme()
                } else {
                    NavigationBarStyler.applyLightTheme()
                }
            }
            
            // Примусово оновлюємо всі навігаційні бари
            NavigationBarStyler.forceRefreshAllNavigationBars()
            
            // Додаткове застосування через UIThemeManager для узгодження всіх елементів
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Визначаємо, чи активована темна тема
                let isDarkMode = mode == .dark || 
                    (mode == .system && UITraitCollection.current.userInterfaceStyle == .dark)
                
                // Застосовуємо відповідні налаштування
                UIThemeManager.shared.applyTheme(isDarkMode: isDarkMode)
                
                // Примусово оновлюємо ще раз
                NavigationBarStyler.forceRefreshAllNavigationBars()
                
                print("SettingsView: Additional theme refresh applied, isDarkMode=\(isDarkMode)")
            }
        }
        
        print("SettingsView: Theme changed to \(mode)")
    }
    
    // Функція для примусового оновлення навігаційних барів
    private func forceUpdateAllNavigationBars() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            recursiveUpdateNavBars(in: window.rootViewController)
        }
    }
    
    // Рекурсивно оновлює всі NavigationController в ієрархії
    private func recursiveUpdateNavBars(in viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        
        if let navigationController = viewController as? UINavigationController {
            // Примусово запускаємо оновлення UI
            navigationController.navigationBar.layoutIfNeeded()
        }
        
        // Обробляємо презентовані контролери
        if let presented = viewController.presentedViewController {
            recursiveUpdateNavBars(in: presented)
        }
        
        // Обробляємо дочірні контролери
        for child in viewController.children {
            recursiveUpdateNavBars(in: child)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                Group {
                    if colorScheme == .dark {
                        // Для темної теми використовуємо однаковий колір з різною прозорістю
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("bottomBacground").opacity(0.95),
                                Color("bottomBacground")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    } else {
                        // Для світлої теми залишаємо як є
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("topBacground"),
                                Color("bottomBacground")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
                }
                
                VStack {
                    List {
                        Section(header: Text("Appearance")) {
                            VStack(spacing: 15) {
                                Text("Theme")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(textColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 5)
                                
                                // Смужка з кнопками вибору теми
                                HStack(spacing: 0) {
                                    // Light theme button
                                    themeButton(mode: .light, icon: "sun.max.fill", title: "Light", iconColor: .orange)
                                    
                                    // Dark theme button
                                    themeButton(mode: .dark, icon: "moon.fill", title: "Dark", iconColor: .purple)
                                    
                                    // System theme button
                                    themeButton(mode: .system, icon: "gearshape.fill", title: "System", iconColor: .gray)
                                }
                                .padding(.bottom, 5)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                        
                        Section(header: Text("Player")) {
                            NavigationLink(destination: PlayerBackgroundSettingsView()) {
                                HStack {
                                    Image(systemName: themeManager.playerBackgroundMode.icon)
                                        .foregroundColor(themeManager.playerBackgroundMode.iconColor)
                                        .imageScale(.large)
                                        .frame(width: 30, height: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Background Style")
                                            .fontWeight(.medium)
                                            .foregroundColor(textColor)
                                        
                                        Text(themeManager.playerBackgroundMode.description)
                                            .font(.caption)
                                            .foregroundColor(secondaryTextColor)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(Color.clear)
                        }
                        
                        Section(header: Text("About")) {
                            HStack {
                                Image(systemName: "music.note")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                                    .frame(width: 30, height: 30)
                                
                                Text("FlexMusic Version 1.0")
                                    .fontWeight(.medium)
                                    .foregroundColor(textColor)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PlayerBackgroundSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black.opacity(0.75)
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            Group {
                if colorScheme == .dark {
                    // Для темної теми використовуємо однаковий колір з різною прозорістю
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("bottomBacground").opacity(0.95),
                            Color("bottomBacground")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                } else {
                    // Для світлої теми залишаємо як є
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("topBacground"),
                            Color("bottomBacground")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
            
            VStack(spacing: 20) {
                // Заголовок та опис
                VStack(spacing: 10) {
                    Text("Player Background")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(textColor)
                    
                    Text("Choose how the player background appears")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Варіанти фону плеєра
                VStack(spacing: 15) {
                    // Статичний градієнт
                    bgOptionCard(
                        isSelected: themeManager.playerBackgroundMode == .staticGradient,
                        title: "Static Gradient",
                        description: "Classic look with a consistent gradient background",
                        iconName: "rectangle.fill",
                        previewGradient: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                        action: { themeManager.playerBackgroundMode = .staticGradient }
                    )
                    
                    // Динамічний фон
                    bgOptionCard(
                        isSelected: themeManager.playerBackgroundMode == .dynamic,
                        title: "Dynamic Colors",
                        description: "Background adapts to the colors of album artwork",
                        iconName: "rectangle.on.rectangle",
                        previewGradient: [Color.orange.opacity(0.7), Color.pink.opacity(0.7), Color.purple.opacity(0.7)],
                        action: { themeManager.playerBackgroundMode = .dynamic }
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Player Background")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func bgOptionCard(
        isSelected: Bool,
        title: String,
        description: String,
        iconName: String,
        previewGradient: [Color],
        action: @escaping () -> Void
    ) -> some View {
        let borderColor = isSelected ? Color.green.opacity(0.5) : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
        
        Button(action: action) {
            HStack(spacing: 16) {
                // Превью градієнта
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: previewGradient),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 60, height: 80)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                // Текстовий опис
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Індикатор вибору
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                        .padding(.trailing, 8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ThemeManager.shared)
    }
}
