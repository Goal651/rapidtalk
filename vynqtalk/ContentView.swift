//
//  ContentView.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var nav: NavigationCoordinator
    
    var body: some View {
        NavigationStack(path: $nav.path) {
            WelcomeScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .welcome:
                        WelcomeScreen()
                    case .login:
                        LoginScreen()
                    case .register:
                        RegisterScreen()
                    case .home:
                        HomeScreen()
                    case .chat(let userId):
                        ChatScreen(userId: userId)
                    }
                }
        }
    }
}
