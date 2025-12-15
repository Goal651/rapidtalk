//
//  AuthViewModel.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import Foundation
import SwiftUI

class AuthViewModel:ObservableObject{
    @AppStorage("loggedIn") var loggedIn: Bool = false
    
    func login(email:String,password:String)->Bool{
        let result = email == "wigo@gmail.com"
        loggedIn = result
        return result
    }
    
    func register(email:String,name:String,password:String) -> Bool{
        return true
    }
}
