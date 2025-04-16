//
//  ProfileView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject var viewManager: ViewManager
    @StateObject var authViewModel : AuthModel
    
    @Binding var isSheetPresent: Bool
    @Binding var userModel : UserModel?
    
    @State var editProfile: Bool = false
    @State var name : String = ""
    @State var email : String = ""
    @State var password : String = ""
    
    
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
                    Text(userModel!.name)
                } else {
                    TextField("name", text: $name)
                        .background(.ultraThinMaterial)
                }
            }
            
            
            
            Text("Email:  \(userModel!.email)")
                if password != "google"{
                    if !editProfile {
                        Button("Edit Profile") {
                            editProfile = true
                        }
                    } else {
                        Button("Save") {
                            userModel?.name = name
                            editProfile = false
                        }
                    }
                }
                
                Button("Logout") {
                    
                    isSheetPresent.toggle()
                    
                    withAnimation{
                        viewManager.navigateToLogin()
                    }
                    
                    authViewModel.logout()
                }
        }
        .onAppear(){
            name = userModel!.name
            email = userModel!.email
        }
    }
}

