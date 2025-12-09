//
//  User.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//
import Foundation

struct User : Identifiable{
    let id = UUID()
    let name : String
    let email : String
}
