//
//  FlexMusicApp.swift
//  FlexMusic
//
//  Created by Aleks Synelnyk on 18.03.2025.
//


import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct AddSongView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var isImporting = false
    @State private var title = ""
    @State private var artist = ""
    @State private var genre = ""
    @State private var year = ""
    @State private var duration = 0.0
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
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
                    Section(header: Text("Song Information").foregroundColor(.white)) {
                        TextField("Title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                        
                        TextField("Artist", text: $artist)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                        
                        TextField("Genre", text: $genre)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                        
                        TextField("Year", text: $year)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .foregroundColor(.white)
                    }
                    
                    Section(header: Text("Cover Image").foregroundColor(.white)) {
                        Button(action: { showingImagePicker = true }) {
                            HStack {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                } else {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                }
                                
                                Text(selectedImage == nil ? "Select Cover Image" : "Change Cover Image")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    Section(header: Text("Audio File").foregroundColor(.white)) {
                        Button(action: { isImporting = true }) {
                            Label("Import Audio File", systemImage: "music.note")
                                .foregroundColor(.white)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add New Song")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
                    .foregroundColor(.white),
                trailing: Button("Save") { saveSong() }
                    .foregroundColor(.white)
                    .disabled(title.isEmpty || artist.isEmpty)
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    if let file = files.first {
                        importAudioFile(from: file)
                    }
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveSong() {
        let newSong = Song(context: viewContext)
        newSong.title = title
        newSong.artist = artist
        newSong.genre = genre
        newSong.year = Int16(year) ?? 0
        newSong.duration = duration
        
        if let image = selectedImage {
            newSong.coverImageData = image.jpegData(compressionQuality: 0.8)
        }
        
        if let imageData = selectedImage?.jpegData(compressionQuality: 0.8) {
            newSong.artwork = imageData
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving song: \(error.localizedDescription)")
        }
        
        dismiss()
    }
    
    private func importAudioFile(from url: URL) {
        // Get the documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Could not access documents directory")
            return
        }
        
        // Create a unique filename
        let fileName = url.lastPathComponent
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Copy the file to the documents directory
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Set the file path
            if let song = try? viewContext.fetch(Song.fetchRequest()).last {
                song.filePath = destinationURL.path
                try? viewContext.save()
            }
        } catch {
            print("Error importing file: \(error.localizedDescription)")
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddSongView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
