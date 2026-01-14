import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadMe() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // The API returns User directly, not wrapped in APIResponse
            let userData: User = try await APIClient.shared.makeDirectRequest("/user")
            user = userData
        } catch {
            errorMessage = error.localizedDescription
            user = nil
        }
    }
}


