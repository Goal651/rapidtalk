//
//  SuspensionHandler.swift
//  vynqtalk
//
//  Handles user suspension across the app
//

import Foundation
import SwiftUI

class SuspensionHandler: ObservableObject {
    @Published var isSuspended = false
    @Published var suspensionMessage = ""
    
    static let shared = SuspensionHandler()
    
    private init() {}
    
    // MARK: - Handle Suspension
    
    func handleSuspension(message: String = "Your account has been suspended.") {
        DispatchQueue.main.async {
            self.isSuspended = true
            self.suspensionMessage = message
        }
        
        // Clear user session
        clearUserSession()
        
        #if DEBUG
        print("🚫 User suspended: \(message)")
        #endif
    }
    
    func handleUnsuspension() {
        DispatchQueue.main.async {
            self.isSuspended = false
            self.suspensionMessage = ""
        }
        
        #if DEBUG
        print("✅ User unsuspended")
        #endif
    }
    
    // MARK: - Session Management
    
    private func clearUserSession() {
        // Clear stored tokens
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "user_data")
        
        // Disconnect WebSocket
        NotificationCenter.default.post(name: .userSuspended, object: nil)
    }
    
    // MARK: - API Error Handling
    
    func handleAPIError(_ error: APIError) {
        switch error {
        case .authenticationRequired:
            handleSuspension(message: "Your session has expired due to account suspension.")
        case .invalidCredentials(let message):
            // Don't handle invalid credentials as suspension
            break
        case .serverError(let statusCode) where statusCode == 403:
            handleSuspension(message: "Your account has been suspended. Please contact support.")
        default:
            break
        }
    }
    
    func handleHTTPResponse(_ response: HTTPURLResponse) {
        if response.statusCode == 403 {
            handleSuspension(message: "Your account has been suspended during this session.")
        }
        // Don't handle 401 here since we now parse the response body in APIClient
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let userSuspended = Notification.Name("userSuspended")
}

// MARK: - Suspension Alert View

struct SuspensionAlertView: View {
    @ObservedObject var suspensionHandler = SuspensionHandler.shared
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        if suspensionHandler.isSuspended {
            ZStack {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(AppTheme.AccentColors.error)
                    
                    // Title
                    Text("Account Suspended")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.primary)
                    
                    // Message
                    Text(suspensionHandler.suspensionMessage)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Contact support
                    Text("If you believe this is an error, please contact our support team.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AppTheme.TextColors.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Action button
                    Button(action: {
                        authVM.logout()
                        suspensionHandler.handleUnsuspension()
                    }) {
                        Text("Return to Login")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.AccentColors.primary)
                            )
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.BackgroundColors.secondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.AccentColors.error.opacity(0.3), lineWidth: 2)
                        )
                )
                .padding(.horizontal, 40)
            }
        }
    }
}