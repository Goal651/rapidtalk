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
     
       
    }
    
}
