//
//  Modal.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//
import SwiftUI

struct ModalView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("This is a modal")
                .font(.title2)
            
            Button("Close") {
                dismiss() // closes the modal
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
    }
}
