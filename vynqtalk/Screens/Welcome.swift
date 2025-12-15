//
//  Welcome.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI

struct WelcomeScreen: View {
    @State private var wave = false
    
    var body: some View {
        ZStack {
            // Dark mode gradient background
            LinearGradient(
                colors: [
                    Color.black,
                    Color.blue.opacity(0.4),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 50) {
                
                // Title + waving icon
                VStack(spacing: 12) {
                    Text("Welcome Back\nTo Vynqtalk")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Image(systemName: "hand.wave.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.yellow.opacity(0.9))
                        .rotationEffect(.degrees(wave ? 15 : -15))
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                            value: wave
                        )
                        .onAppear { wave = true }
                }
                .padding(.top, 40)
                
                
                // Login button
                NavigationLink(destination: LoginScreen()) {
                    Text("Login")
                        .font(.title3.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: .white.opacity(0.1), radius: 10, y: 4)
                        .padding(.horizontal, 40)
                }
                
                
                // OR Divider (subtle for dark mode)
                HStack {
                    line
                    Text("OR")
                        .foregroundColor(.white.opacity(0.8))
                        .fontWeight(.medium)
                    line
                }
                .padding(.horizontal, 40)
                
                
                // Register button
                NavigationLink(destination: RegisterScreen()) {
                    Text("Register")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.7), radius: 10, y: 4)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
        }
    }
    
    // Clean divider line
    private var line: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(.white.opacity(0.3))
    }
}
