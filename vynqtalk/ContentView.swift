//
//  ContentView.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var nav: NavigationCoordinator
    @AppStorage("loggedIn") private var loggedIn: Bool = false
    
    var body: some View {
        NavigationStack(path: $nav.path) {
            Group {
                if loggedIn {
                    MainTabView()
                } else {
                    WelcomeScreen()
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                Group {
                    switch route {
                    case .welcome:
                        WelcomeScreen()
                    case .login:
                        LoginScreen()
                    case .register:
                        RegisterScreen()
                    case .main:
                        MainTabView()
                    case .chat(let userId, let name):
                        ChatScreen(userId: userId, userName: name)
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    )
                )
            }
        }
        .animation(.easeInOut(duration: AppTheme.AnimationDuration.slow), value: nav.path)
    }
}
