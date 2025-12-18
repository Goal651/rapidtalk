import Foundation

class User: Codable, Identifiable {
    let id: Int?
    let name: String?
    let avatar: String?
    let password: String?
    let email: String?
    let userRole: UserRole?
    let status: String?
    let bio: String?
    let lastActive: Date?
    let createdAt: Date?
    let latestMessage: Message?
    let unreadMessages: [Message]?
    let online: Bool?

    public init(id: Int?, name: String?, avatar: String?, password: String?, email: String?, userRole: UserRole?, status: String?, bio: String?, lastActive: Date?, createdAt: Date?, latestMessage: Message?, unreadMessages: [Message]?, online: Bool?) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.password = password
        self.email = email
        self.userRole = userRole
        self.status = status
        self.bio = bio
        self.lastActive = lastActive
        self.createdAt = createdAt
        self.latestMessage = latestMessage
        self.unreadMessages = unreadMessages
        self.online = online
    }
}
