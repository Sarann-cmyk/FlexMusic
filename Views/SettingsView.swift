//
//  SettingsView.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 23.03.2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
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
                        Section(header: Text("Appearance")) {
                            NavigationLink(destination: ThemeSettingsView()) {
                                HStack {
                                    Image(systemName: themeManager.themeMode.icon)
                                        .foregroundColor(themeManager.themeMode.iconColor)
                                        .imageScale(.large)
                                        .frame(width: 30, height: 30)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Theme")
                                            .fontWeight(.medium)
                                        
                                        Text(themeManager.themeMode.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
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
                                        
                                        Text(themeManager.playerBackgroundMode.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Section(header: Text("About")) {
                            HStack {
                                Image(systemName: "music.note")
                                    .foregroundColor(.blue)
                                    .imageScale(.large)
                                    .frame(width: 30, height: 30)
                                
                                Text("FlexMusic Version 1.0")
                                    .fontWeight(.medium)
                            }
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

struct ThemeSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                themeManager.themeMode = mode
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PlayerBackgroundSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
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
                    Section(header: Text("Background Style")) {
                        ForEach(PlayerBackgroundMode.allCases, id: \.rawValue) { mode in
                            HStack {
                                Image(systemName: mode.icon)
                                    .foregroundColor(mode.iconColor)
                                    .imageScale(.large)
                                    .frame(width: 30, height: 30)
                                
                                VStack(alignment: .leading) {
                                    Text(mode.description)
                                        .fontWeight(.medium)
                                        
                                    if mode == .dynamic {
                                        Text("Changes based on album artwork")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Default gradient background")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if themeManager.playerBackgroundMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                themeManager.playerBackgroundMode = mode
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Player Background")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ThemeManager.shared)
    }
}
