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
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "chevron.left")
                    .font(AppTheme.Typography.title3)
                Text("Back")
                    .font(AppTheme.Typography.body)
            }
        }
        .foregroundColor(AppTheme.TextColors.primary)
        .padding(.leading, AppTheme.Spacing.m)
    }
}
