//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI
import CoreData

struct AddPlaylistView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    
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
                
                Form {
                    Section(header: Text("Playlist Information").foregroundColor(.white)) {
                        TextField("Title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(.white),
                trailing: Button("Create") { createPlaylist() }
                    .foregroundColor(.white)
                    .disabled(title.isEmpty)
            )
        }
    }
    
    private func createPlaylist() {
        let newPlaylist = Playlist(context: viewContext)
        newPlaylist.title = title
        
        do {
            try viewContext.save()
        } catch {
            print("Error creating playlist: \(error.localizedDescription)")
        }
        
        dismiss()
    }
} 
