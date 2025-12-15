//
//  vynqtalkApp.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//

import SwiftUI

@main
struct vynqtalkApp: App {
    @StateObject var userVM=UserViewModel()
    @StateObject var authVM=AuthViewModel()
    @StateObject var messageVM=MessageViewModel()
    @StateObject var wsM=WebSocketManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userVM)
                .environmentObject(authVM)
                .environmentObject(messageVM)
                .environmentObject(wsM)
                
        }
    }
}



