//
//  AuthViewModel.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//

import Foundation
import SwiftUI

class AuthViewModel:ObservableObject{
    let api=APIClient.shared
    
    @AppStorage("loggedIn") var loggedIn: Bool = false
    
    func login(email:String,password:String)async ->Bool{
        do{
            let data = LoginRequest(email: email, password: password)
            let response: APIResponse<LoginResponse> = try await api.post("/auth/login", data: data)
            print(response)
            let result = email == "wigo@gmail.com"
            return result
        }catch{
            print(error.localizedDescription)
            return false
        }
    }
    
    func register(email:String,name:String,password:String) -> Bool{
        return true
    }
}
