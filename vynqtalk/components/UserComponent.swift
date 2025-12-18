//
//  User.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//
import SwiftUI

struct UserComponent : View, Codable, Identifiable{
    var id:Int?
    var user:User

    var body: some View{
        HStack(spacing: 12){
            // User Avatar
            Image(systemName: user.avatar ?? "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4){
                // User Name and Online Status
                HStack{
                    Text(user.name ?? "Unknown User")
                        .font(.headline)
                        .foregroundColor(.white)

                    if user.online == true {
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(.green)
                    }
                }

                // User Email (optional)
                if let email = user.email, !email.isEmpty {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // User Bio (optional)
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Optional: User Status or Last Active
            if let status = user.status, !status.isEmpty {
                Text(status)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
    }
}
