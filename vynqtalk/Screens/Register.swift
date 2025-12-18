//
//  Register.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI

struct RegisterScreen: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showModal: Bool = false
    
    @AppStorage("loggedIn") var loggedIn: Bool = false
    
    func isValidEmail(_ email: String) -> Bool {
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
    
    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    var body: some View {
        ZStack {
            // Background
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
            
            VStack(spacing: 30) {
                // Title
                VStack(spacing: 6) {
                    Text("Create your account")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.title3)
                    
                    Text("Register")
                        .foregroundColor(.white)
                        .font(.system(size: 36, weight: .bold))
                }
                .padding(.top, 45)
                
                // Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                    
                    TextField("Enter your name", text: $name)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 40)
                
                // Email
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
                    }
                }
                .padding(.horizontal, 40)
                
                // Password
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                    
                    SecureField("Enter password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 40)
                
                // Confirm Password
                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm Password")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.subheadline)
                    
                    SecureField("Re-enter password", text: $confirmPassword)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    !confirmPassword.isEmpty && !passwordsMatch
                                        ? Color.red.opacity(0.6)
                                        : Color.white.opacity(0.25),
                                    lineWidth: 1
                                )
                        )
                    
                    if !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 40)
                
                // Register button
                Button {
                    let result = authVM.register(
                        email: email, name: name, password: password
                    )
                    
                    if result {
                        loggedIn = true
                        withAnimation { showModal = true }
                    }
                } label: {
                    Text("Register")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: .white.opacity(0.1), radius: 10, y: 5)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            
            // Modal
            if showModal {
                ModalView(
                    title: "Account Created!",
                    description: "Welcome to Vynqtalk 🎉",
                    onClose: { withAnimation {
                        showModal = false
                        nav.reset(to: .home)
                    } }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
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
