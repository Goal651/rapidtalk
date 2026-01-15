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
          
            let userData: APIResponse<User> = try await APIClient.shared
                .makeDirectRequest("/user")
            user = userData.data

        } catch {
            print("  Profile loading error: \(error)")
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

    }
    
    // MARK: - Avatar Upload
    
    func uploadAvatar(imageData: Data) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let filename = "avatar_\(UUID().uuidString).jpg"
            let response: APIResponse<User> = try await APIClient.shared.uploadAvatar(
                imageData: imageData,
                filename: filename
            )
            
            if response.success, let updatedUser = response.data {
                user = updatedUser
                print("✅ Avatar uploaded successfully: \(updatedUser.avatar ?? "no avatar")")
            } else {
                errorMessage = response.message
                print("  Avatar upload failed: \(response.message)")
            }
        } catch {
            errorMessage = "Failed to upload avatar: \(error.localizedDescription)"
            print("  Avatar upload error: \(error)")
        }
    }
}

