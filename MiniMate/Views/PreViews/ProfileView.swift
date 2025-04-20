//
//  ProfileView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage

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
    
    /// for bottom error text
    @State private var botMessage: String = ""
    
    /// to show password or not
    @State private var isSecure: Bool = true
    
    /// if message is red vs green
    @State private var isRed: Bool = true
    
    /// Selected User profile image
    @State private var selectedImage: UIImage?
    
    /// shows photopicker
    @State private var isShowingImagePicker = false
    
    @ViewBuilder
    private var userDetailsSection: some View {
        Section("User Details") {
            if let user = userModel {
                HStack {
                    Text("Name:")
                    if !editProfile {
                        Text(user.mini.name)
                    } else {
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: name) { newValue, oldValue in
                                if newValue.count > 30 {
                                    name = String(newValue.prefix(30))
                                }
                            }
                    }
                }

                UserInfoRow(label: "Email", value: user.email!)
                UserInfoRow(label: "UID", value: user.mini.id)

                if let user = authModel.user, !user.providerData.contains(where: { $0.providerID == "google.com" }) {
                    
                    Button("Password Reset") {
                        Auth.auth().sendPasswordReset(withEmail: email) { error in
                            if let error = error {
                                botMessage = error.localizedDescription
                                isRed = true
                            } else {
                                isRed = false
                                botMessage = "Password reset email sent!"
                            }
                        }
                    }
                
                    /// For future update
                    //Button("Change Photo") {
                    //    isShowingImagePicker = true
                    //}
                    //.fullScreenCover(isPresented: $isShowingImagePicker, content: {
                    //    ImagePicker(selectedImage: $selectedImage)
                    //})
                    //.onChange(of: selectedImage) { newImage, _ in
                    //    if let image = newImage {
                    //        authModel.updateProfileImage(image) { result in
                    //            switch result {
                    //            case .success(let url):
                    //                print("✅ Photo updated! URL: \(url)")
                    //            case .failure(let error):
                    //                print("❌ Error updating photo: \(error.localizedDescription)")
                    //            }
                    //        }
                    //   }
                    //}
                    
                    EditProfileButton(editProfile: $editProfile) {
                        userModel!.mini.name = name
                        authModel.saveUserData(user: userModel!) { _ in }
                        editProfile = false
                    } onToggle: {
                        editProfile = true
                    }

                }

            } else {
                Text("User data not available.")
            }
        }
    }

    @ViewBuilder
    private var accountManagementSection: some View {
        Section("Account Management") {
            Button("Logout") {
                isSheetPresent.toggle()
                withAnimation {
                    viewManager.navigateToWelcome()
                }
                authModel.logout()
            }
            .foregroundColor(.red)

            Button("Delete Account") {
                if let user = authModel.user, user.providerData.contains(where: { $0.providerID == "google.com" }) {
                        showDeleteConfirmation = true
                    } else {
                        withAnimation {
                            showLoginOverlay = true
                    }
                }
            }
            .foregroundColor(.red)
        }
        .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                authModel.deleteAccount { result in
                    if result == "true" {
                        showDeleteConfirmation = false
                        isSheetPresent.toggle()
                        withAnimation {
                            viewManager.navigateToWelcome()
                        }
                        context.delete(userModel!)
                    } else {
                        botMessage = result
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and data.")
        }
    }

    @ViewBuilder
    private var messageSection: some View {
        if !botMessage.isEmpty {
            Section("Message") {
                Text(botMessage)
                    .foregroundColor(isRed ? .red : .green)
            }
        }
    }
    
    
    var body: some View {
        ZStack {
            VStack {
                // Header and drag indicator
                Capsule()
                    .frame(width: 38, height: 6)
                    .foregroundColor(.gray)
                    .padding(10)
                
                HStack{
                    Text("Profile")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.leading, 30)
                    Spacer()
                }
                
                List {
                    userDetailsSection
                    accountManagementSection
                    messageSection
                }
                .onAppear {
                    if let user = userModel {
                        name = user.mini.name
                        email = user.email!
                    }
                }
            }
            /// LoginOverlay
            if showLoginOverlay {
                ReauthViewOverlay(viewManager: viewManager, authModel: authModel, showLoginOverlay: $showLoginOverlay, isSheetPresent: $isSheetPresent, userModel: $userModel)
                .cornerRadius(20)
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

struct UserInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("\(label):")
            Text(value)
        }
    }
}

struct EditProfileButton: View {
    @Binding var editProfile: Bool
    let onSave: () -> Void
    let onToggle: () -> Void

    var body: some View {
        Button(editProfile ? "Save" : "Edit Profile") {
            if editProfile {
                onSave()
            } else {
                onToggle()
            }
        }
    }
}

