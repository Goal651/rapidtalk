//
//  APIEnvironment.swift
//  vynqtalk
//
//  Created by Kiro AI
//

import Foundation

enum APIEnvironment {
    case development
    case staging
    case production
    case custom(String)
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:8080"
        case .staging:
            return "https://staging-api.vynqtalk.com"
        case .production:
            return "https://api.vynqtalk.com"
        case .custom(let url):
            return url
        }
    }
    
    var wsURL: String {
        switch self {
        case .development:
            return "ws://localhost:8080"
        case .staging:
            return "wss://staging-api.vynqtalk.com"
        case .production:
            return "wss://api.vynqtalk.com"
        case .custom(let url):
            // Convert http/https to ws/wss
            return url
                .replacingOccurrences(of: "https://", with: "wss://")
                .replacingOccurrences(of: "http://", with: "ws://")
        }
    }
}
