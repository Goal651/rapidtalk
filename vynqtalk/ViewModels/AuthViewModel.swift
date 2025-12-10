//
//  AuthViewModel.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//
import Foundation
import SwiftUI

class AuthViewModel:ObservableObject{
    @AppStorage("loggedIn") var loggedIn:Bool = false
    
    
    func login(email:String,password:String)->Bool{
        let result=email=="wigothehacker"
        loggedIn = result
        return result
        
           
    }
}
