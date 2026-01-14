import Foundation

struct Reaction: Codable {
    let emoji: String
    let userId: String  // Changed from Int to String (UUID)
}
