//
//  SettingsView.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 23.03.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var dynamicBackgroundManager = DynamicBackgroundManager.shared
    @StateObject private var audioManager = AudioManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isDynamicBackgroundEnabled") private var isDynamicBackgroundEnabled = true
    @AppStorage("isSleepTimerEnabled") private var isSleepTimerEnabled = false
    @AppStorage("sleepTimerDuration") private var sleepTimerDuration = 30
    @AppStorage("isPlaybackSpeedEnabled") private var isPlaybackSpeedEnabled = false
    @AppStorage("playbackSpeed") private var playbackSpeed = 1.0
    @AppStorage("skipSilenceAtEnd") private var skipSilenceAtEnd = false
    @AppStorage("selectedLanguage") private var selectedLanguage: String = Locale.current.languageCode ?? "en"
    @State private var feedbackText: String = ""
    @State private var showFeedbackAlert = false
    @State private var showFeedback = false
    
    var body: some View {
        let _ = localizationManager.currentLanguage
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("topBacground"),
                        Color("bottomBacground")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    List {
                        Section(header: Text(localizationManager.localizedString(forKey: "theme"))) {
                            Menu {
                                ForEach(ThemeMode.allCases, id: \.rawValue) { mode in
                                    Button(action: {
                                        withAnimation {
                                            themeManager.themeMode = mode
                                        }
                                    }) {
                                        Label(mode.description, systemImage: mode.icon)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: themeManager.themeMode.icon)
                                        .foregroundColor(themeManager.themeMode.iconColor)
                                        .imageScale(.large)
                                        .frame(width: 30, height: 30)
                                    VStack(alignment: .leading) {
                                        Text(localizationManager.localizedString(forKey: "theme"))
                                            .fontWeight(.medium)
                                        Text(themeManager.themeMode.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        
                        Section(header: Text(localizationManager.localizedString(forKey: "language"))) {
                            Picker(selection: $selectedLanguage, label: HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                                    .frame(width: 30, height: 30)
                                Text(localizationManager.localizedString(forKey: "language"))
                                    .fontWeight(.medium)
                            }) {
                                Text(localizationManager.localizedString(forKey: "english")).tag("en")
                                Text(localizationManager.localizedString(forKey: "ukrainian")).tag("uk")
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedLanguage) { lang in
                                LocalizationManager.shared.setLanguage(lang)
                            }
                        }
                        .listRowBackground(Color.clear)
                        
                        Section(header: Text(localizationManager.localizedString(forKey: "dynamic_background"))) {
                            Toggle(isOn: $dynamicBackgroundManager.isDynamicBackgroundEnabled) {
                                HStack {
                                    Image(systemName: "paintpalette")
                                        .foregroundColor(.blue)
                                        .imageScale(.large)
                                        .frame(width: 30, height: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text("dynamic_background".localized)
                                            .fontWeight(.medium)
                                        
                                        Text("Background color changes with album art")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                        
                        Section(header: Text("skip_silence".localized)) {
                            Toggle("skip_silence".localized, isOn: $skipSilenceAtEnd)
                                .onChange(of: skipSilenceAtEnd) { newValue in
                                    print("⚙️ Skip silence setting changed to: \(newValue)")
                                    audioManager.skipSilenceAtEnd = newValue
                                    if newValue && audioManager.isPlaying {
                                        print("🔍 Starting silence detection after enabling")
                                        audioManager.startSilenceDetection()
                                    }
                                }
                            .listRowBackground(Color.clear)
                        }
                        
                        Section(header: Text("about".localized)) {
                            HStack {
                                Image(systemName: "music.note")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                                    .frame(width: 30, height: 30)
                                Text("version".localized)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .listRowBackground(Color.clear)
                            Button(action: { showFeedback = true }) {
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.blue)
                                        .imageScale(.large)
                                        .frame(width: 30, height: 30)
                                    Text(localizationManager.localizedString(forKey: "feedback"))
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("settings".localized)
                        .foregroundColor(Color("playerControls"))
                        .font(.headline)
                }
            }
            .alert("Не вдалося відкрити поштовий клієнт", isPresented: $showFeedbackAlert) {
                Button("OK", role: .cancel) { }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
        }
    }
    
    private func sendFeedback() {
        let email = "ieremiay@gmail.com"
        let subject = "Відгук про FlexMusic"
        let trimmed = feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailto = "mailto:\(email)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        if let url = URL(string: mailto) {
            UIApplication.shared.open(url) { success in
                if success { feedbackText = "" }
                else { showFeedbackAlert = true }
            }
        } else {
            showFeedbackAlert = true
        }
    }
}

struct ThemeSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isUpdating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("topBacground"),
                    Color("bottomBacground")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                List {
                    Section(header: Text("Theme Mode")) {
                        ForEach(ThemeMode.allCases, id: \.rawValue) { mode in
                            Button(action: {
                                isUpdating = true
                                withAnimation {
                                    themeManager.themeMode = mode
                                }
                                
                                // Примусово оновлюємо інтерфейс
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window = windowScene.windows.first {
                                        window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
                                        if let navigationController = window.rootViewController?.navigationController {
                                            navigationController.navigationBar.setNeedsLayout()
                                            navigationController.navigationBar.layoutIfNeeded()
                                            navigationController.navigationBar.standardAppearance = UINavigationBar.appearance().standardAppearance
                                            navigationController.navigationBar.compactAppearance = UINavigationBar.appearance().compactAppearance
                                            navigationController.navigationBar.scrollEdgeAppearance = UINavigationBar.appearance().scrollEdgeAppearance
                                        }
                                    }
                                    isUpdating = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: mode.icon)
                                        .foregroundColor(mode.iconColor)
                                        .imageScale(.large)
                                        .frame(width: 30, height: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text(mode.description)
                                            .fontWeight(.medium)
                                        
                                        if mode == .system {
                                            Text("Follow system settings")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if themeManager.themeMode == mode {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isUpdating)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Theme")
                        .foregroundColor(Color("playerControls"))
                        .font(.headline)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ThemeManager.shared)
    }
}
