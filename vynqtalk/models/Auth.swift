//
//  Auth.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/15/25.
//

import Foundation

struct LoginRequest:Encodable{
    let email:String
    let password:String 
}


struct LoginResponse:Decodable{
    let user:User
    let accessToken:String
}
