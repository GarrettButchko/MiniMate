//
//  ProfileView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    
    @StateObject var userData: AuthViewModel
    @StateObject var viewManager: ViewManager
    
    @State var editProfile: Bool = false
    @Binding var isSheetPresent: Bool
    
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
                    //Text(name here)
                } else {
                    TextField("name", text: $name)
                        .background(.ultraThinMaterial)
                }
            }
            
            
            
            Text("Email:  \(email)")
                if password != "google"{
                    if !editProfile {
                        Button("Edit Profile") {
                            editProfile = true
                        }
                    } else {
                        Button("Save") {
                           
                        }
                    }
                }
                
                Button("Logout") {
                    
                    isSheetPresent.toggle()
                    
                    withAnimation{
                        viewManager.navigateToLogin()
                    }
                    
                    userData.logout()
                }
        }
    }
}

