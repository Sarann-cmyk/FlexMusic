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
                            Button(action: {
                                themeManager.themeMode = mode
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ThemeManager.shared)
    }
}
