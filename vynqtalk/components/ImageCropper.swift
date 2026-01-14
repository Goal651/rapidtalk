//
//  ImageCropper.swift
//  vynqtalk
//
//  Image cropping view for profile pictures
//

import SwiftUI
import UIKit

struct ImageCropper: View {
    @Environment(\.dismiss) var dismiss
    let image: UIImage
    let onCrop: (UIImage) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height) - 40
                    
                    ZStack {
                        // Image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1), 4)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        
                        // Crop overlay
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                            .frame(width: size, height: size)
                        
                        // Dimmed overlay
                        Rectangle()
                            .fill(.black.opacity(0.5))
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .mask(
                                Rectangle()
                                    .overlay(
                                        Circle()
                                            .frame(width: size, height: size)
                                            .blendMode(.destinationOut)
                                    )
                            )
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .navigationTitle("Crop Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        cropImage()
                    }
                    .foregroundColor(AppTheme.AccentColors.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func cropImage() {
        let croppedImage = cropToCircle(image: image, scale: scale, offset: offset)
        onCrop(croppedImage)
        dismiss()
    }
    
    private func cropToCircle(image: UIImage, scale: CGFloat, offset: CGSize) -> UIImage {
        let size: CGFloat = 500 // Output size
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        let croppedImage = renderer.image { context in
            // Create circular clipping path
            let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
            path.addClip()
            
            // Calculate image drawing rect
            let imageSize = image.size
            let aspectRatio = imageSize.width / imageSize.height
            
            var drawWidth: CGFloat
            var drawHeight: CGFloat
            
            if aspectRatio > 1 {
                drawHeight = size * scale
                drawWidth = drawHeight * aspectRatio
            } else {
                drawWidth = size * scale
                drawHeight = drawWidth / aspectRatio
            }
            
            let x = (size - drawWidth) / 2 + offset.width
            let y = (size - drawHeight) / 2 + offset.height
            
            image.draw(in: CGRect(x: x, y: y, width: drawWidth, height: drawHeight))
        }
        
        return croppedImage
    }
}
