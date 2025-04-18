//
//  ProfileView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

/// Displays and allows editing of the current user's profile
struct ProfileView: View {
    @Environment(\.modelContext) private var context
    
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthModel
    
    /// Controls sheet dismissal
    @Binding var isSheetPresent: Bool
    
    /// The user currently signed in
    @Binding var userModel: UserModel?
    
    /// Toggles between view and edit mode
    @State private var editProfile: Bool = false
    
    @Binding var showLoginOverlay : Bool
    @State private var showDeleteConfirmation = false
    
    /// Form fields (used for editing)
    @State private var name: String = ""
    @State private var email: String = ""
    
    @State private var error: String = ""
    
    
    var body: some View {
        ZStack {
            VStack {
                // Header and drag indicator
                Capsule()
                    .frame(width: 38, height: 6)
                    .foregroundColor(.gray)
                    .padding(10)
                
                Text("Profile")
                    .frame(width: 250, height: 40)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                
                List {
                    // ... your existing list sections ...
                    Section("User Details") {
                        if let user = userModel {
                            HStack {
                                Text("Name:")
                                if !editProfile {
                                    Text(user.name)
                                } else {
                                    TextField("Name", text: $name)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            
                            // MARK: - Email (View Only)
                            HStack {
                                Text("Email:")
                                Text(user.email)
                            }
                            
                            // MARK: - Email (View Only)
                            HStack {
                                Text("UID:")
                                Text(user.id)
                            }
                            
                            if user.password != nil {
                                Button(editProfile ? "Save" : "Edit Profile") {
                                    if editProfile {
                                        userModel?.name = name
                                    }
                                    editProfile.toggle()
                                }
                            }
                        } else {
                            Text("User data not available.")
                        }
                    }
                    
                    Section("Account Management") {
                        
                        Button("Logout") {
                            isSheetPresent.toggle()
                            withAnimation {
                                viewManager.navigateToLogin()
                            }
                            authModel.logout()
                        }
                        .foregroundColor(.red)
                        
                        Button("Delete Account") {
                            /// user = current user
                            if let user = Auth.auth().currentUser {
                                /// checks if user is a google user
                                let isGoogleUser = user.providerData.contains { $0.providerID == "google.com" }
                                /// if google user it deletes account
                                if isGoogleUser {
                                    
                                    showDeleteConfirmation = true
                                    
                                    /// if user is not a google user
                                } else {
                                    withAnimation {
                                        showLoginOverlay = true
                                    }
                                }
                            }
                            
                        }
                        .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
                            Button("Delete", role: .destructive) {
                                authModel.deleteAccount { result in
                                    /// if succsessfully deleted account
                                    if result == "true"{
                                        /// Removes notification for delete function
                                        showDeleteConfirmation = false
                                        /// Removes profile view
                                        isSheetPresent.toggle()
                                        /// Deletes userModel from local storage
                                        context.delete(userModel!)
                                        ///transitions to login
                                        withAnimation {
                                            viewManager.navigateToLogin()
                                        }
                                        /// didn't succsessfully delete account
                                    } else {
                                        error = result
                                    }
                                }
                            }
                            /// Cancel button in Notification
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            /// Notification button title
                            Text("This will permanently delete your account and data.")
                        }
                        .foregroundColor(.red)
                        
                        
                    }
                    
                    /// Error in Profile View
                    if error != "" {
                        Section("Error") {
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                }
                .onAppear {
                    if let user = userModel {
                        name = user.name
                        email = user.email
                    }
                }
            }
            /// LoginOverlay
            if showLoginOverlay {
                ReauthViewOverlay(
                    viewManager: viewManager,
                    authModel: authModel,
                    showLoginOverlay: $showLoginOverlay
                )
                .cornerRadius(20)
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }

}
