//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI
import CoreData

struct SongDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let song: Song
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedArtist: String
    @State private var editedGenre: String
    @State private var editedYear: String
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    init(song: Song) {
        self.song = song
        _editedTitle = State(initialValue: song.title ?? "")
        _editedArtist = State(initialValue: song.artist ?? "")
        _editedGenre = State(initialValue: song.genre ?? "")
        _editedYear = State(initialValue: String(song.year))
        if let imageData = song.coverImageData {
            _selectedImage = State(initialValue: UIImage(data: imageData))
        }
    }
    
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Cover Image
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(12)
                        } else {
                            Image(systemName: "music.note")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .foregroundColor(.white)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        if isEditing {
                            Button(action: { showingImagePicker = true }) {
                                Text("Change Cover Image")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        
                        VStack(spacing: 16) {
                            if isEditing {
                                TextField("Title", text: $editedTitle)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .foregroundColor(.white)
                                
                                TextField("Artist", text: $editedArtist)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .foregroundColor(.white)
                                
                                TextField("Genre", text: $editedGenre)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .foregroundColor(.white)
                                
                                TextField("Year", text: $editedYear)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .foregroundColor(.white)
                            } else {
                                Text(song.title ?? "Untitled")
                                    .font(.title)
                                    .foregroundColor(.white)
                                
                                Text(song.artist ?? "Unknown Artist")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                if let genre = song.genre {
                                    Text(genre)
                                        .font(.headline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                }
                                
                                if song.year > 0 {
                                    Text(String(song.year))
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            Text(formatDuration(song.duration))
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        
                        if let filePath = song.filePath {
                            Button(action: {
                                // TODO: Implement play functionality
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Play")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") { dismiss() }
                    .foregroundColor(.white),
                trailing: Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
                .foregroundColor(.white)
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private func saveChanges() {
        song.title = editedTitle
        song.artist = editedArtist
        song.genre = editedGenre
        song.year = Int16(editedYear) ?? 0
        
        if let image = selectedImage {
            song.coverImageData = image.jpegData(compressionQuality: 0.8)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving changes: \(error.localizedDescription)")
        }
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    SongDetailView(song: Song())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
