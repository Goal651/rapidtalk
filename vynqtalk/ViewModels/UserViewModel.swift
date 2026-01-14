//
//  UserViewModel.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//

import Foundation


class UserViewModel:ObservableObject{
    @Published var users:[User]=[]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
        Task { await loadUsers() }
    }
    
    @MainActor
    func loadUsers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response: APIResponse<[User]> = try await APIClient.shared.get("/users")
            guard response.success, let data = response.data else {
                errorMessage = response.message
                users = []
                return
            }
            users = data
        } catch {
            errorMessage = error.localizedDescription
            users = []
        }
    }
    
}
