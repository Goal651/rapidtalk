import Foundation

enum AppRoute: Hashable {
    case welcome
    case login
    case register
    case home
    case chat(userId: Int)
}


