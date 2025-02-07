//
//  ProfileView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//


import SwiftUI

struct ProfileView: View {
    @StateObject var viewManager: ViewManager
    @StateObject var authViewModel: AuthViewModel
    @State var name: String = "N/A"
    @State var editProfile: Bool = false
    
    var body: some View {
        
        VStack{
            
            Capsule()
                .frame(width: 38, height: 6)
                .foregroundColor(.gray)
                .padding(10)
            
            Text("Profile")
                .frame(width: 250, height: 40)
                .font(.title)
                .foregroundColor(.primary)
                .fontWeight(.bold)

        }
        
        List{
            HStack{
                Text("Name:")
                if !editProfile{
                    Text(name)
                } else {
                    TextField("name", text: $name)
                        .background(.ultraThinMaterial)
                }
            }
            
            
            
            Text("Email:  \(authViewModel.user?.email ?? "No email")")
            
            
            if authViewModel.user != nil {
                
                if !editProfile {
                    Button("Edit Profile") {
                        editProfile = true
                    }
                } else {
                    Button("Save") {
                        editProfile = false
                        authViewModel.saveUserData(key: "name", data: name, completion: { _ in })
                    }
                }
                
                Button("Logout") {
                    withAnimation{
                        viewManager.navigateToLogin()
                    }
                    authViewModel.logout()
                    name = "N/A"
                }
                
            } else {
                Button(action: {
                    withAnimation{
                        viewManager.navigateToLogin()
                    }
                }) {
                    Text("Login")
                }
            }
        }
        .onAppear(){
            authViewModel.fetchUserData(key: "name", completion: { name in
            
                self.name = name!
                    
            })
        }
    }
}

