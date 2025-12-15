//
//  Login.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI

struct LoginScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var wsM:WebSocketManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showModal: Bool = false
    @AppStorage("loggedIn") var loggedIn: Bool = false
    
    func isValidEmail(_ email: String) -> Bool {
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color.black,
                    Color.blue.opacity(0.35),
                    Color.black.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 30) {
                // Title
                VStack(spacing: 6) {
                    Text("Welcome Back \(loggedIn)")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.title3)
                    
                    Text("Login")
                        .foregroundColor(.white)
                        .font(.system(size: 36, weight: .bold))
                }
                .padding(.top, 45)
                
                // Email Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                    
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    !email.isEmpty && !isValidEmail(email)
                                        ? Color.red.opacity(0.6)
                                        : Color.white.opacity(0.25),
                                    lineWidth: 1
                                )
                        )
                    
                    if !isValidEmail(email) && !email.isEmpty {
                        Text("Invalid email format")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.leading, 4)
                    }
                }
                .padding(.horizontal, 40)
                
                // Password Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                    
                    SecureField("Enter your password", text: $password)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 40)
                
                // Login button
                Button(action: {
                    Task{
//                        let result: Bool = await authVM.login(email: email, password: password)
                        wsM.connect(token: "whowhe")
                        withAnimation {
                            showModal = false
                        }
                    }
                }) {
                    Text("Login")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: .white.opacity(0.1), radius: 10, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
                
                // Forgot password
                Button(action: {}) {
                    Text("Forgot Password?")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.footnote)
                }
                .padding(.top, 5)
                
                Spacer()
            }
            
            // Modal overlay
            if showModal {
                ModalView(
                    title: "Success!",
                    description: "You have successfully logged in.",
                    onClose: { withAnimation {
                        showModal = false
                       
                    }  }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1) // ensure it's above main content
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
    }
}
