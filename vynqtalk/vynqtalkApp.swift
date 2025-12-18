//
//  vynqtalkApp.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//

import SwiftUI

@main
struct vynqtalkApp: App {
    @StateObject private var nav: NavigationCoordinator
    @StateObject private var userVM: UserViewModel
    @StateObject private var authVM: AuthViewModel
    @StateObject private var messageVM: MessageViewModel
    @StateObject private var wsM: WebSocketManager

    init() {
        let nav = NavigationCoordinator()
        _nav = StateObject(wrappedValue: nav)
        _userVM = StateObject(wrappedValue: UserViewModel())
        _authVM = StateObject(wrappedValue: AuthViewModel(nav: nav))
        _messageVM = StateObject(wrappedValue: MessageViewModel())
        _wsM = StateObject(wrappedValue: WebSocketManager())
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(nav)
                .environmentObject(userVM)
                .environmentObject(authVM)
                .environmentObject(messageVM)
                .environmentObject(wsM)
                
        }
    }
}



