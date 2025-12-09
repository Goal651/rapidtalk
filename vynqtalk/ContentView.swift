//
//  ContentView.swift
//  vynqtalk
//
//  Created by wigothehacker on 12/9/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userVM:UserViewModel
    
    var body: some View {
        VStack {
            Image(systemName:"bubble")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Welcome To Vynqtalk Applicatioin")
            List(userVM.users){user in
                UserComponent(user:user)
            }
        }
        .padding()
    }
}
