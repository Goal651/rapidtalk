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
            // Try to load user data from the API
            let userData: APIResponse<User> = try await APIClient.shared
                .makeDirectRequest("/user")
            user = userData.data

        } catch {
            print("❌ Profile loading error: \(error)")
            errorMessage = error.localizedDescription
            user = nil

            // If API fails, create a fallback user with stored data
            createFallbackUser()
        }
    }

    private func createFallbackUser() {
        // Create a fallback user with stored auth data
        let storedUserId =
            UserDefaults.standard.string(forKey: "user_id") ?? "unknown"
        let storedEmail =
            UserDefaults.standard.string(forKey: "user_email")
            ?? "user@example.com"
        let storedName =
            UserDefaults.standard.string(forKey: "user_name") ?? "User"

        user = User(
            id: storedUserId,
            name: storedName,
            avatar: nil,
            password: nil,
            email: storedEmail,
            userRole: .user,
            status: "Available",
            bio: "VynqTalk user",
            lastActive: Date(),
            createdAt: Date(),
            latestMessage: nil,
            unreadMessages: nil,
            online: true
        )

        print("📝 Created fallback user: \(storedName)")
    }
}
