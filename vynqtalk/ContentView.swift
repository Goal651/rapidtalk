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
                destinationView(for: route)
                    .toolbar(route.hidesTabBar ? .hidden : .visible, for: .tabBar)
            }
        }
        .sheet(item: $nav.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .alert(item: $nav.alert) { config in
            if let secondaryButton = config.secondaryButton {
                return Alert(
                    title: Text(config.title),
                    message: config.message.map { Text($0) },
                    primaryButton: alertButton(config.primaryButton),
                    secondaryButton: alertButton(secondaryButton)
                )
            } else {
                return Alert(
                    title: Text(config.title),
                    message: config.message.map { Text($0) },
                    dismissButton: alertButton(config.primaryButton)
                )
            }
        }
        .animation(.easeInOut(duration: AppTheme.AnimationDuration.slow), value: nav.path)
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
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
    
    @ViewBuilder
    private func sheetView(for sheet: AppSheet) -> some View {
        switch sheet {
        case .userProfile(let userId):
            Text("User Profile: \(userId)")
        case .imageViewer(let url):
            Text("Image Viewer: \(url)")
        case .settings:
            Text("Settings")
        }
    }
    
    private func alertButton(_ button: AlertConfig.AlertButton) -> Alert.Button {
        switch button.style {
        case .default:
            return .default(Text(button.title), action: button.action)
        case .cancel:
            return .cancel(Text(button.title), action: button.action)
        case .destructive:
            return .destructive(Text(button.title), action: button.action)
        }
    }
}
