//
//  AuthViewModel.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import Foundation
import SwiftUI

class AuthViewModel:ObservableObject{
    let api=APIClient.shared
    private let nav: NavigationCoordinator
    
    @AppStorage("loggedIn") var loggedIn: Bool = false
    @AppStorage("token") var authToken:String = " "

    init(nav: NavigationCoordinator) {
        self.nav = nav
    }
    
    @MainActor
    func login(email: String, password: String) async -> Bool {
        do {
            let payload = LoginRequest(email: email, password: password)

            let response: APIResponse<LoginResponse> =
                try await APIClient.shared.post("/auth/login", data: payload)

            guard response.success,
                  let loginData = response.data else {
                return false
            }

            // ✅ accessToken is NOT optional
            APIClient.shared.saveAuthToken(loginData.accessToken)
            APIClient.shared.loggedIn = true
            authToken=loginData.accessToken

            nav.reset(to: .home)
            return true

        } catch {
            print("Login error:", error)
            return false
        }
    }

    
    func register(email:String,name:String,password:String) -> Bool{
        return true
    }
}
