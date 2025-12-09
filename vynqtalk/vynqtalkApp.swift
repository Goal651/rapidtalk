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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userVM)
        }
    }
}



