//
//  Home.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI


struct HomeScreen: View {
    @EnvironmentObject var userVM:UserViewModel
    @EnvironmentObject var nav: NavigationCoordinator
    
    var body: some View {
        ZStack {
            // Background (same theme)
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
            
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                Text("Users")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 25)
                    .padding(.top, 45)
                
                // User list
                ScrollView {
                    VStack(spacing: 14) {
                        if userVM.users.isEmpty {
                            Text("No users yet")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 30)
                        } else {
                            ForEach(userVM.users) { user in
                                Button {
                                    nav.push(.chat(userId: user.id ?? 0))
                                } label: {
                                    UserComponent(user: user)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 10)
                }
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden()
    }
}
