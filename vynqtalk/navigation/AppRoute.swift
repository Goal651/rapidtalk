import Foundation

enum AppRoute: Hashable {
    case welcome
    case login
    case register
    case main
    case chat(userId: String, name: String, avatar: String?, lastActive: Date?)  // Changed from Int to String
    
    // Route metadata
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .login: return "Login"
        case .register: return "Register"
        case .main: return "Chats"
        case .chat(_, let name, _, _): return name
        }
    }
    
    var requiresAuth: Bool {
        switch self {
        case .welcome, .login, .register:
            return false
        default:
            return true
        }
    }
    
    var hidesTabBar: Bool {
        switch self {
        case .chat:
            return true
        default:
            return false
        }
    }
    
    var allowsSwipeBack: Bool {
        switch self {
        case .welcome, .main:
            return false
        default:
            return true
        }
    }
}

// MARK: - Sheet Presentation

enum AppSheet: Identifiable {
    case userProfile(userId: String)  // Changed from Int to String
    case imageViewer(url: String)
    case settings
    
    var id: String {
        switch self {
        case .userProfile(let userId): return "userProfile_\(userId)"
        case .imageViewer(let url): return "imageViewer_\(url)"
        case .settings: return "settings"
        }
    }
}

// MARK: - Alert Configuration

struct AlertConfig: Identifiable {
    let id = UUID()
    let title: String
    let message: String?
    let primaryButton: AlertButton
    let secondaryButton: AlertButton?
    
    struct AlertButton {
        let title: String
        let style: ButtonStyle
        let action: () -> Void
        
        enum ButtonStyle {
            case `default`
            case cancel
            case destructive
        }
    }
}


