//
//  UserExtensions.swift
//  vynqtalk
//
//  Extensions for User model
//

import Foundation

extension User {
    /// Returns the full avatar URL by combining base URL with relative path
    var avatarURL: URL? {
        guard let avatar = avatar else { return nil }
        
        // If already a full URL, return it
        if avatar.lowercased().hasPrefix("http://") || avatar.lowercased().hasPrefix("https://") {
            return URL(string: avatar)
        }
        
        // Construct full URL from base URL + relative path
        let baseURL = APIClient.environment.baseURL
        let cleanPath = avatar.hasPrefix("/") ? avatar : "/\(avatar)"
        let fullURLString = "\(baseURL)\(cleanPath)"
        
        return URL(string: fullURLString)
    }
    
    /// Returns true if user has a valid avatar
    var hasAvatar: Bool {
        return avatarURL != nil
    }
}
