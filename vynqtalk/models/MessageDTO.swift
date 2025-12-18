import Foundation

class Message: Codable, Identifiable {
    let id: Int?
    let content: String?
    let type: MessageType?
    let sender: User?
    let receiver: User?
    let timestamp: Date?
    let fileName: String?
    let edited: Bool?
    let reactions: [Reaction]?
    let replyTo: Message?

    public init(id: Int?, content: String?, type: MessageType?, sender: User?, receiver: User?, timestamp: Date?, fileName: String?, edited: Bool?, reactions: [Reaction]?, replyTo: Message?) {
        self.id = id
        self.content = content
        self.type = type
        self.sender = sender
        self.receiver = receiver
        self.timestamp = timestamp
        self.fileName = fileName
        self.edited = edited
        self.reactions = reactions
        self.replyTo = replyTo
    }
}
