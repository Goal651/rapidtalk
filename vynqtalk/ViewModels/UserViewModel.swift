//
//  UserViewModel.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//

import Foundation


class UserViewModel:ObservableObject{
    @Published var users:[User]=[]
    
    init() {
        self.loadUsers()
    }
    
    func loadUsers(){
        // TODO: replace with real API call
        if !users.isEmpty { return }

        let me = User(
            id: 1,
            name: "Me",
            avatar: "",
            password: "",
            email: "me@example.com",
            userRole: .user,
            status: "online",
            bio: "Building Vynqtalk",
            lastActive: Date(),
            createdAt: Date(),
            latestMessage: nil,
            unreadMessages: [],
            online: true
        )

        let friend = User(
            id: 2,
            name: "Alex",
            avatar: "",
            password: "",
            email: "alex@example.com",
            userRole: .user,
            status: "online",
            bio: "Hey 👋",
            lastActive: Date(),
            createdAt: Date(),
            latestMessage: nil,
            unreadMessages: [],
            online: true
        )

        let friend2 = User(
            id: 3,
            name: "Sam",
            avatar: "",
            password: "",
            email: "sam@example.com",
            userRole: .user,
            status: "offline",
            bio: "Last seen recently",
            lastActive: Date().addingTimeInterval(-3600),
            createdAt: Date(),
            latestMessage: nil,
            unreadMessages: [],
            online: false
        )

        users = [friend, friend2, me]
    }
    
}
