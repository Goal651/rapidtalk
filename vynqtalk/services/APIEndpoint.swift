//
//  APIEndpoint.swift
//  vynqtalk
//
//  Created by Kiro AI
//

import Foundation

enum APIEndpoint {
    // MARK: - Authentication
    case login
    case signup
    case currentUser
    
    // MARK: - Users
    case users
    case userSearch(query: String)
    case userById(id: String)  // Changed from Int to String
    case updateUserStatus(id: String)  // Changed from Int to String
    
    // MARK: - Messages
    case conversation(user1: String, user2: String)  // Changed from Int to String
    case sendMessage
    
    var path: String {
        switch self {
        // Authentication
        case .login:
            return "/auth/login"
        case .signup:
            return "/auth/signup"
        case .currentUser:
            return "/user"
            
        // Users
        case .users:
            return "/users"
        case .userSearch(let query):
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            return "/users/search?query=\(encoded)"
        case .userById(let id):
            return "/users/\(id)"
        case .updateUserStatus(let id):
            return "/users/\(id)/status"
            
        // Messages
        case .conversation(let user1, let user2):
            return "/messages/conversation/\(user1)/\(user2)"
        case .sendMessage:
            return "/messages"
        }
    }
}
