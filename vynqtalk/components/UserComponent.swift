//
//  User.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//
import SwiftUI
import Foundation

struct UserComponent: View {
    let user: User

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            avatar

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.s) {
                    Text(user.name ?? "Unknown User")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.TextColors.primary)

                    if user.online == true {
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(AppTheme.AccentColors.success)
                            .accessibilityLabel("Online")
                    }
                }

                if let email = user.email, !email.isEmpty {
                    Text(email)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.TextColors.secondary)
                }

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.TextColors.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let status = user.status, !status.isEmpty {
                Text(status)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(AppTheme.TextColors.tertiary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.m)
        .padding(.horizontal, AppTheme.Spacing.m)
        .background(AppTheme.SurfaceColors.surfaceLight)
        .cornerRadius(AppTheme.CornerRadius.l)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
    
    private var accessibilityDescription: String {
        var description = user.name ?? "Unknown User"
        
        if user.online == true {
            description += ", online"
        } else {
            description += ", offline"
        }
        
        if let email = user.email, !email.isEmpty {
            description += ", \(email)"
        }
        
        if let bio = user.bio, !bio.isEmpty {
            description += ", \(bio)"
        }
        
        if let status = user.status, !status.isEmpty {
            description += ", status: \(status)"
        }
        
        return description
    }

    @ViewBuilder
    private var avatar: some View {
        if let avatarString = user.avatar,
           let url = URL(string: avatarString),
           avatarString.lowercased().hasPrefix("http") {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 50, height: 50)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(AppTheme.TextColors.secondary)
                @unknown default:
                    EmptyView()
                }
            }
            .overlay(Circle().stroke(AppTheme.TextColors.tertiary, lineWidth: 1))
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(AppTheme.TextColors.secondary)
                .overlay(Circle().stroke(AppTheme.TextColors.tertiary, lineWidth: 1))
        }
    }
}
