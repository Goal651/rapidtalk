//
//  BackButton.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI

struct BackButton: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var nav: NavigationCoordinator

    var body: some View {
        Button(action: {
            if nav.path.count == 0 {
                dismiss()
            } else {
                nav.pop()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                Text("Back")
                    .font(.body)
            }
        }
        .foregroundColor(.white)
        .padding(.leading)
    }
}
