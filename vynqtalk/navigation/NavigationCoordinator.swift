import SwiftUI

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var presentedSheet: AppSheet?
    @Published var alert: AlertConfig?
    
    // Navigation history
    private(set) var history: [AppRoute] = []

    // MARK: - Stack Navigation
    
    func push(_ route: AppRoute) {
        history.append(route)
        path.append(route)
        logNavigation(route, action: "push")
    }

    func pop() {
        guard path.count > 0 else { return }
        path.removeLast()
        if !history.isEmpty {
            history.removeLast()
        }
        logNavigation(nil, action: "pop")
    }

    func popToRoot() {
        guard path.count > 0 else { return }
        path.removeLast(path.count)
        history.removeAll()
        logNavigation(nil, action: "popToRoot")
    }
    
    func replace(with route: AppRoute) {
        if !history.isEmpty {
            history.removeLast()
        }
        if path.count > 0 {
            path.removeLast()
        }
        push(route)
    }

    func reset(to route: AppRoute) {
        popToRoot()
        push(route)
    }
    
    // MARK: - Modal Navigation
    
    func presentSheet(_ sheet: AppSheet) {
        presentedSheet = sheet
        logNavigation(nil, action: "presentSheet: \(sheet.id)")
    }
    
    func dismissSheet() {
        presentedSheet = nil
        logNavigation(nil, action: "dismissSheet")
    }
    
    // MARK: - Alerts
    
    func showAlert(_ config: AlertConfig) {
        alert = config
        logNavigation(nil, action: "showAlert: \(config.title)")
    }
    
    func dismissAlert() {
        alert = nil
        logNavigation(nil, action: "dismissAlert")
    }
    
    // MARK: - Analytics
    
    private func logNavigation(_ route: AppRoute?, action: String) {
        #if DEBUG
        if let route = route {
            print("📱 Navigation: \(action) -> \(route)")
        } else {
            print("📱 Navigation: \(action)")
        }
        #endif
    }
}


