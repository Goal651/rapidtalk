//
//  UltraMediaPicker.swift
//  vynqtalk
//
//  Ultra-Refined Media Picker - Perfect Apple Quality
//  In-app media selection and upload
//

import SwiftUI
import PhotosUI
import AVFoundation

struct UltraMediaPicker: View {
    @Binding var isPresented: Bool
    let onMediaSelected: (MediaItem) -> Void
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showDocumentPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Perfect header
                ultraHeader
                
                // Perfect options
                ultraOptions
                
                Spacer()
            }
            .background(UltraTheme.Backgrounds.gradient)
        }
        .photosPicker(
            isPresented: .constant(!selectedItems.isEmpty),
            selection: $selectedItems,
            maxSelectionCount: 1,
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: selectedItems) { items in
            handleSelectedItems(items)
        }
        .sheet(isPresented: $showCamera) {
            UltraCameraPicker { mediaItem in
                onMediaSelected(mediaItem)
                isPresented = false
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            UltraDocumentPicker { url in
                let mediaItem = MediaItem(type: .file, url: url, fileName: url.lastPathComponent)
                onMediaSelected(mediaItem)
                isPresented = false
            }
        }
    }
    
    // MARK: - Perfect Header
    
    private var ultraHeader: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .foregroundColor(UltraTheme.Accent.primary)
            .font(UltraTheme.Typography.body)
            
            Spacer()
            
            Text("Add Media")
                .font(UltraTheme.Typography.title)
                .foregroundColor(UltraTheme.Text.primary)
            
            Spacer()
            
            // Invisible button for balance
            Button("Cancel") {
                isPresented = false
            }
            .opacity(0)
        }
        .padding(UltraTheme.Layout.l)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Perfect Options
    
    private var ultraOptions: some View {
        VStack(spacing: UltraTheme.Layout.l) {
            // Photo Library
            UltraMediaOption(
                icon: "photo.on.rectangle",
                title: "Photo Library",
                subtitle: "Choose from your photos and videos"
            ) {
                openPhotoLibrary()
            }
            
            // Camera
            UltraMediaOption(
                icon: "camera",
                title: "Camera",
                subtitle: "Take a photo or record a video"
            ) {
                showCamera = true
            }
            
            // Documents
            UltraMediaOption(
                icon: "doc",
                title: "Documents",
                subtitle: "Share files and documents"
            ) {
                showDocumentPicker = true
            }
        }
        .padding(UltraTheme.Layout.l)
    }
    
    private func openPhotoLibrary() {
        // This will trigger the PhotosPicker
        selectedItems = []
    }
    
    private func handleSelectedItems(_ items: [PhotosPickerItem]) {
        guard let item = items.first else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let mediaItem = MediaItem(
                    type: item.supportedContentTypes.contains(.movie) ? .video : .image,
                    data: data,
                    fileName: "media_\(Date().timeIntervalSince1970)"
                )
                
                await MainActor.run {
                    onMediaSelected(mediaItem)
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Ultra Media Option

struct UltraMediaOption: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    @State private var pressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: UltraTheme.Layout.m) {
                // Perfect icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(UltraTheme.Accent.primary)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(UltraTheme.Accent.primary.opacity(0.1))
                    )
                
                // Perfect content
                VStack(alignment: .leading, spacing: UltraTheme.Layout.xs) {
                    Text(title)
                        .font(UltraTheme.Typography.body)
                        .foregroundColor(UltraTheme.Text.primary)
                    
                    Text(subtitle)
                        .font(UltraTheme.Typography.caption)
                        .foregroundColor(UltraTheme.Text.tertiary)
                }
                
                Spacer()
                
                // Perfect chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(UltraTheme.Text.quaternary)
            }
            .padding(UltraTheme.Layout.m)
            .ultraCard()
            .scaleEffect(pressed ? 0.98 : 1.0)
            .animation(UltraTheme.Motion.spring, value: pressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            pressed = pressing
        }, perform: {})
    }
}

// MARK: - Ultra Camera Picker

struct UltraCameraPicker: UIViewControllerRepresentable {
    let onMediaCaptured: (MediaItem) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onMediaCaptured: onMediaCaptured, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onMediaCaptured: (MediaItem) -> Void
        let dismiss: DismissAction
        
        init(onMediaCaptured: @escaping (MediaItem) -> Void, dismiss: DismissAction) {
            self.onMediaCaptured = onMediaCaptured
            self.dismiss = dismiss
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                let mediaItem = MediaItem(
                    type: .image,
                    data: data,
                    fileName: "photo_\(Date().timeIntervalSince1970).jpg"
                )
                onMediaCaptured(mediaItem)
            } else if let videoURL = info[.mediaURL] as? URL {
                do {
                    let data = try Data(contentsOf: videoURL)
                    let mediaItem = MediaItem(
                        type: .video,
                        data: data,
                        fileName: "video_\(Date().timeIntervalSince1970).mp4"
                    )
                    onMediaCaptured(mediaItem)
                } catch {
                    print("Failed to load video data: \(error)")
                }
            }
            
            dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

// MARK: - Ultra Document Picker

struct UltraDocumentPicker: UIViewControllerRepresentable {
    let onDocumentSelected: (URL) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentSelected: onDocumentSelected, dismiss: dismiss)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentSelected: (URL) -> Void
        let dismiss: DismissAction
        
        init(onDocumentSelected: @escaping (URL) -> Void, dismiss: DismissAction) {
            self.onDocumentSelected = onDocumentSelected
            self.dismiss = dismiss
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onDocumentSelected(url)
            dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            dismiss()
        }
    }
}

// MARK: - Media Item Model

struct MediaItem {
    let type: MessageType
    let data: Data?
    let url: URL?
    let fileName: String
    
    init(type: MessageType, data: Data, fileName: String) {
        self.type = type
        self.data = data
        self.url = nil
        self.fileName = fileName
    }
    
    init(type: MessageType, url: URL, fileName: String) {
        self.type = type
        self.data = nil
        self.url = url
        self.fileName = fileName
    }
}