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
        HStack(spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.name ?? "Unknown User")
                        .font(.headline)
                        .foregroundColor(.white)

                    if user.online == true {
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(.green)
                    }
                }

                if let email = user.email, !email.isEmpty {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer()

            if let status = user.status, !status.isEmpty {
                Text(status)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
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
                        .foregroundColor(.white.opacity(0.85))
                @unknown default:
                    EmptyView()
                }
            }
            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.white.opacity(0.85))
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
    }
}
