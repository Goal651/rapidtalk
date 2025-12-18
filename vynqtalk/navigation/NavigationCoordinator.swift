import SwiftUI

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard path.count > 0 else { return }
        path.removeLast()
    }

    func popToRoot() {
        guard path.count > 0 else { return }
        path.removeLast(path.count)
    }

    func reset(to route: AppRoute) {
        popToRoot()
        push(route)
    }
}


