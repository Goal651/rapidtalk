//
//  AdminAnalyticsService.swift
//  vynqtalk
//
//  Admin analytics API service for dashboard graphs
//

import Foundation

// MARK: - Analytics Models

struct AdminAnalytics: Codable {
    let userGrowth: [UserGrowthData]
    let messageActivity: [MessageActivityData]
    let messageTypeDistribution: [MessageTypeData]
}

struct UserGrowthData: Codable, Identifiable {
    let id = UUID()
    let date: String
    let count: Int
    
    var dateValue: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date) ?? Date()
    }
    
    private enum CodingKeys: String, CodingKey {
        case date, count
    }
}

struct MessageActivityData: Codable, Identifiable {
    let id = UUID()
    let date: String
    let count: Int
    
    var dateValue: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date) ?? Date()
    }
    
    private enum CodingKeys: String, CodingKey {
        case date, count
    }
}

struct MessageTypeData: Codable, Identifiable {
    let id = UUID()
    let type: String
    let count: Int
    
    var displayName: String {
        switch type {
        case "TEXT": return "Text"
        case "IMAGE": return "Images"
        case "AUDIO": return "Voice Notes"
        case "VIDEO": return "Videos"
        case "FILE": return "Files"
        default: return type
        }
    }
    
    var emoji: String {
        switch type {
        case "TEXT": return "💬"
        case "IMAGE": return "📷"
        case "AUDIO": return "🎵"
        case "VIDEO": return "🎥"
        case "FILE": return "📎"
        default: return "📄"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, count
    }
}

// MARK: - Analytics Service

extension APIClient {
    func getAdminAnalytics() async throws -> APIResponse<AdminAnalytics> {
        return try await get("/admin/analytics")
    }
}