import Foundation

struct Reaction: Codable, Identifiable {
    let id: String?
    let emoji: String
    let userId: String?
    let user: User?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case emoji
        case userId
        case user
        case message  // Backend sends this but we don't need it
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        emoji = try container.decode(String.self, forKey: .emoji)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        user = try container.decodeIfPresent(User.self, forKey: .user)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        // Ignore the 'message' field from backend
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(emoji, forKey: .emoji)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(user, forKey: .user)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        // Don't encode 'message' field
    }
    
    init(id: String? = nil, emoji: String, userId: String? = nil, user: User? = nil, createdAt: Date? = nil) {
        self.id = id
        self.emoji = emoji
        self.userId = userId
        self.user = user
        self.createdAt = createdAt
    }
}
