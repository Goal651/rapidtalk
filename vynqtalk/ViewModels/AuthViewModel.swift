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
    @AppStorage("auth_token") var authToken: String = ""
    @AppStorage("user_id") var userId: String = ""  // Changed from Int to String

    init(nav: NavigationCoordinator) {
        self.nav = nav
    }
    
    @MainActor
    func logout() {
        APIClient.shared.logout()
        loggedIn = false
        authToken = ""
        userId = ""
        
        // Clear stored user data
        UserDefaults.standard.removeObject(forKey: "user_name")
        UserDefaults.standard.removeObject(forKey: "user_email")
        UserDefaults.standard.removeObject(forKey: "user_id")
        
        nav.popToRoot()
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
            authToken = loginData.accessToken
            userId = loginData.user.id ?? ""
            
            // Store user data for profile
            UserDefaults.standard.set(loginData.user.name, forKey: "user_name")
            UserDefaults.standard.set(loginData.user.email, forKey: "user_email")
            UserDefaults.standard.set(loginData.user.id, forKey: "user_id")
            
            loggedIn = true  // Set the @AppStorage property

            nav.reset(to: .main)
            return true

        } catch {
            print("Login error:", error)
            return false
        }
    }

    
    @MainActor
    func register(email: String, name: String, password: String) async -> Bool {
        do {
            let payload = SignupRequest(email: email, name: name, password: password)
            let response: APIResponse<LoginResponse> =
                try await APIClient.shared.post("/auth/signup", data: payload)

            guard response.success,
                  let signupData = response.data else {
                return false
            }

            APIClient.shared.saveAuthToken(signupData.accessToken)
            APIClient.shared.loggedIn = true
            authToken = signupData.accessToken
            userId = signupData.user.id ?? ""
            
            // Store user data for profile
            UserDefaults.standard.set(signupData.user.name, forKey: "user_name")
            UserDefaults.standard.set(signupData.user.email, forKey: "user_email")
            UserDefaults.standard.set(signupData.user.id, forKey: "user_id")
            
            loggedIn = true  // Set the @AppStorage property

            nav.reset(to: .main)
            return true
        } catch {
            print("Register error:", error)
            return false
        }
    }
}
