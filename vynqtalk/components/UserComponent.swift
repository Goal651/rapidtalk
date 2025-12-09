//
//  User.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//
import SwiftUI

struct UserComponent : View{
    var user:User
    var body: some View{
        HStack{
            Text(user.id.uuidString)
            VStack{
                Text(user.name)
                Text(user.email)
            }
        }
    }
}
