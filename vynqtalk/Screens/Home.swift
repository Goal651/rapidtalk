//
//  Home.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import SwiftUI


struct HomeScreen: View {
    @EnvironmentObject var userVM:UserViewModel
    
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
//                ScrollView {
//                    VStack(spacing: 14) {
//                        ForEach(userVM.users) { user in
//                            HStack(spacing: 15) {
//                                Image(systemName: user.avatar)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 46, height: 46)
//                                    .foregroundColor(.white)
//                                    .background(
//                                        Circle()
//                                            .fill(Color.white.opacity(0.08))
//                                    )
//                                
//                                Text(user.name)
//                                    .foregroundColor(.white)
//                                    .font(.title3)
//                                
//                                Spacer()
//                            }
//                            .padding()
//                            .background(Color.white.opacity(0.06))
//                            .cornerRadius(14)
//                        }
//                    }
//                    .padding(.horizontal, 25)
//                    .padding(.top, 10)
//                }
//                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden()
    }
}
