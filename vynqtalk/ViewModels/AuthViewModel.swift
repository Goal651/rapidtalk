//
//  AuthViewModel.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/10/25.
//
import Foundation

class AuthViewModel:ObservableObject{
    
    func login(email:String,password:String)->Bool{
        return email=="wigo@gmail.com"
           
    }
}
