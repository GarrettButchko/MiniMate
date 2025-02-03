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
        
        HStack{
            Button(action: {
                withAnimation{
                    viewManager.navigateToMain()
                }
            }) {
                ZStack {
                    Circle()
                    VStack {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(width: 30, height: 30)
            .padding(.leading)
            
            Spacer()
            
            Text("Profile")
                .frame(width: 250, height: 40)
                .font(.title)
                .foregroundColor(.primary)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .fontWeight(.bold)
            
            Spacer()
            Spacer()
        }
        
        List{
            HStack{
                Text("Name: ")
                if !editProfile{
                    Text(name)
                } else {
                    TextField("name", text: $name)
                        .background(.ultraThinMaterial)
                }
            }
            
            
            
            Text("Email: \(authViewModel.user?.email ?? "No email")")
            
            
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

