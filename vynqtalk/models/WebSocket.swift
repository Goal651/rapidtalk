import Foundation

struct WsResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String?
}

struct ChatMessagePayload: Encodable {
    let senderId: Int
    let receiverId: Int
    let content: String
    let type: MessageType
    let fileName: String?
    let replyToId: String?  // UUID of the message being replied to
}


