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
        let user0 :User = User( name: "Wigo", email: "wigothehacker@gmail.com")
        let user1 :User = User( name: "Wilson", email: "wigothe@gmail.com")
        let user2 :User = User( name: "Wigo", email: "wigohacker@gmail.com")
        let user3 :User = User( name: "Wigo", email: "thehacker@gmail.com")
        let user4 :User = User( name: "Wigo", email: "hacker@gmail.com")
        users.append(user0)
        users.append(user1)
        users.append(user2)
        users.append(user3)
        users.append(user4)
    }
    
}
