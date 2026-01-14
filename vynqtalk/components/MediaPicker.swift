//
//  MediaPicker.swift
//  vynqtalk
//
//  Media picker for chat attachments
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MediaPicker: UIViewControllerRepresentable {
    @Binding var selectedMedia: MediaItem?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaPicker
        
        init(_ parent: MediaPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let result = results.first else { return }
            
            let itemProvider = result.itemProvider
            
            // Check for image
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.parent.selectedMedia = MediaItem(
                                data: data,
                                type: .image,
                                filename: "image.jpg",
                                mimeType: "image/jpeg",
                                thumbnail: image
                            )
                        }
                    }
                }
            }
            // Check for video
            else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    if let url = url, let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            self.parent.selectedMedia = MediaItem(
                                data: data,
                                type: .video,
                                filename: url.lastPathComponent,
                                mimeType: "video/mp4",
                                thumbnail: nil
                            )
                        }
                    }
                }
            }
        }
    }
}

struct MediaItem: Equatable {
    let data: Data
    let type: MediaType
    let filename: String
    let mimeType: String
    let thumbnail: UIImage?
    
    enum MediaType {
        case image
        case video
        case file
    }
    
    var messageType: MessageType {
        switch type {
        case .image: return .image
        case .video: return .video
        case .file: return .file
        }
    }
    
    // Equatable conformance
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.data == rhs.data &&
        lhs.type == rhs.type &&
        lhs.filename == rhs.filename &&
        lhs.mimeType == rhs.mimeType
        // Note: UIImage is not Equatable, so we skip thumbnail comparison
    }
}
