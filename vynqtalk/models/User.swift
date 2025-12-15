// User.swift
// vynqtalk
// Created by wigothehacker on 12/9/25.

import Foundation

struct User: Identifiable, Decodable {
    let id: Int
    let name: String
    let avatar: String?
    let email: String
    let userRole: String
    let status: String?
    let bio: String?
    let lastActive: String?      // or Date, if backend returns ISO string
    let createdAt: String?       // or Date
}


// Supporting structs
enum UserRole :Decodable{
    case ADMIN
}
