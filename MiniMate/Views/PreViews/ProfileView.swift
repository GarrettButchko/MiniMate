// ProfileView.swift
// MiniMate
//
// Updated to use UserModel and AuthViewModel

import SwiftUI
import FirebaseAuth
import AuthenticationServices

/// Displays and allows editing of the current user's profile
struct ProfileView: View {
    @Environment(\.modelContext) private var context
    
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    
    @Binding var isSheetPresent: Bool
    @Binding var showLoginOverlay: Bool
    
    @State private var editProfile: Bool = false
    @State private var showGoogleDeleteConfirmation: Bool = false
    @State private var showAppleDeleteConfirmation: Bool = false
    
    @State private var showAdminLogin: Bool = false
    @State private var adminCode: String = ""
    
    @State private var name: String = ""
    @State private var email: String = ""
    
    @State private var botMessage: String = ""
    @State private var isRed: Bool = true
    
    @State private var reauthCoordinator = AppleReauthCoordinator { _ in }
    
    @State private var showingPhotoPicker = false
    @State private var pickedImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            VStack {
                // Header and drag indicator
                Capsule()
                    .frame(width: 38, height: 6)
                    .foregroundColor(.gray)
                    .padding(10)
                
                HStack {
                    Text("Profile")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.leading, 30)
                    Spacer()
                    Text("Tap to change photo")
                        .font(.caption)
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        if let photoURL = authModel.firebaseUser?.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image("logoOpp")
                                    .resizable()
                                    .scaledToFill()
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image("logoOpp")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.trailing, 30)
                }
                .sheet(isPresented: $showingPhotoPicker) {
                    PhotoPicker(image: $pickedImage)
                        .onChange(of: pickedImage) { old ,newImage in
                            guard let img = newImage else { return }
                            authModel.uploadProfilePhoto(img) { result in
                                switch result {
                                case .success(let url):
                                    print("✅ Photo URL:", url)
                                case .failure(let error):
                                    print("❌ Photo upload failed:", error)
                                }
                            }
                        }
                }
                
                List {
                    // User Details Section
                    Section("User Details") {
                        if let user = authModel.userModel {
                            HStack {
                                Text("Name:")
                                if editProfile {
                                    TextField("Name", text: $name)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: name) { _, newValue in
                                            if newValue.count > 30 {
                                                name = String(newValue.prefix(30))
                                            }
                                        }
                                } else {
                                    Text(user.name)
                                }
                            }
                            
                            HStack {
                                Text("Email:")
                                Text(user.email ?? "")
                            }
                            
                            HStack {
                                Text("UID:")
                                Text(user.id)
                            }
                            
                            HStack {
                                Text("Is Pro User:")
                                Text(String(user.isPro))
                            }
                            
                            // Only allow edit/reset for non-social accounts
                            if let firebaseUser = authModel.firebaseUser,
                               !firebaseUser.providerData.contains(where: { $0.providerID == "google.com" || $0.providerID == "apple.com" }) {
                                Button(editProfile ? "Save" : "Edit Profile") {
                                    if editProfile {
                                        authModel.userModel?.name = name
                                        authModel.saveUserModel(authModel.userModel!) { _ in }
                                        editProfile = false
                                    } else {
                                        name = user.name
                                        editProfile = true
                                    }
                                }
                                
                                Button("Password Reset") {
                                    let targetEmail = user.email ?? ""
                                    Auth.auth().sendPasswordReset(withEmail: targetEmail) { error in
                                        if let error = error {
                                            botMessage = error.localizedDescription
                                            isRed = true
                                        } else {
                                            botMessage = "Password reset email sent!"
                                            isRed = false
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("User data not available.")
                        }
                    }
                    
<<<<<<< HEAD
=======
                    Section("Admin") {
                        if (authModel.userModel?.adminType) == nil{
                            Button("Login As Admin") {
                                showAdminLogin = true
                            }
                            .alert("Use your admin code to login", isPresented: $showAdminLogin) {
                                TextField("Admin Code", text: $adminCode)
                                Button("Login") {
                                    if AdminCodeResolver.isAdminCodeThere(code: adminCode) {
                                        authModel.userModel?.adminType = AdminCodeResolver.adminAndId[adminCode]?.id
                                        authModel.saveUserModel(authModel.userModel!) { _ in }
                                    }
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("This will log you into your admin account.")
                            }
                            
                        } else {
                            Text("Admin of: \(authModel.userModel?.adminType ?? "Unknown")")
                            
                            Button("Logout of Admin Account") {
                                authModel.userModel?.adminType = nil
                                authModel.saveUserModel(authModel.userModel!) { _ in }
                            }
                        }
                    }
                    
>>>>>>> online
                    // Account Management Section
                    Section("Account Management") {
                        if authModel.userModel?.id != "IDGuest" {
                            Button("Logout") {
                                isSheetPresent = false
                                withAnimation {
                                    viewManager.navigateToWelcome()
                                }
                                authModel.logout()
                            }
                            .foregroundColor(.red)
                        }
                        

                        Button("Delete Account") {
                            if let firebaseUser = authModel.firebaseUser {
                                if firebaseUser.providerData.contains(where: { $0.providerID == "google.com" }) {
                                    showGoogleDeleteConfirmation = true
                                } else if firebaseUser.providerData.contains(where: { $0.providerID == "apple.com" }) {
                                    showAppleDeleteConfirmation = true
                                } else {
                                    showLoginOverlay = true
                                }
                            } else {
                                viewManager.navigateToWelcome()
                                context.delete(authModel.userModel!)
                            }
                        }
                        .foregroundColor(.red)
                        // Google delete confirmation
                        .alert("Confirm Deletion", isPresented: $showGoogleDeleteConfirmation) {
                            Button("Delete", role: .destructive) {
                                authModel.reauthenticateWithGoogle { reauthResult in
                                    switch reauthResult {
                                    case .success(let credential):
                                        authModel.deleteAccount(reauthCredential: credential) { deleteResult in
                                            switch deleteResult {
                                            case .success:
                                                viewManager.navigateToWelcome()
                                                
                                                if let userModel = authModel.userModel {
                                                    for game in userModel.games {
                                                        context.delete(game)
                                                    }
                                                    context.delete(LocFuncs().fetchUser(by: "IDGuest", context: context)!)
                                                }
                                            case .failure(let error):
                                                botMessage = error.localizedDescription
                                                isRed = true
                                            }
                                        }
                                    case .failure(let error):
                                        botMessage = error.localizedDescription
                                        isRed = true
                                    }
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will permanently delete your account and all data.")
                        }
                        // Apple delete confirmation
                        .alert("Confirm Deletion", isPresented: $showAppleDeleteConfirmation) {
                            Button("Delete", role: .destructive) {
                                startAppleReauthAndDelete()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will permanently delete your account and all data.")
                        }
                    }
                    
                    // Bot Message Section
                    if !botMessage.isEmpty {
                        Section("Message") {
                            Text(botMessage)
                                .foregroundColor(isRed ? .red : .green)
                        }
                    }
                }
                .onAppear {
                    if let user = authModel.userModel {
                        name = user.name
                        email = user.email ?? ""
                    }
                }
            }
            
            // Reauth Overlay
            if showLoginOverlay {
                ReauthViewOverlay(
                    viewManager: viewManager,
                    authModel: authModel,
                    showLoginOverlay: $showLoginOverlay,
                    isSheetPresent: $isSheetPresent
                )
                .cornerRadius(20)
                .zIndex(1)
            }
        }
    }
    
    /// Starts Sign in with Apple solely to reauthenticate, then deletes the account.
    private func startAppleReauthAndDelete() {
        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        request.requestedScopes = []
        
        let nonce = authModel.randomNonceString()
        authModel.currentNonce = nonce
        request.nonce = authModel.sha256(nonce)
        
        // Install handler
        reauthCoordinator.onAuthorize = { result in
            switch result {
            case .failure(let err):
                botMessage = err.localizedDescription
                isRed = true
                showAppleDeleteConfirmation = false
                
            case .success(let authorization):
                authModel.deleteAppleAccount(using: authorization) { deletionResult in
                    switch deletionResult {
                    case .success():
                        viewManager.navigateToWelcome()
                        
                        if let userModel = authModel.userModel {
                            let model = UserModel(id: userModel.id, name: userModel.name, photoURL: nil, email: userModel.email, games: [])
                            for game in userModel.games {
                                context.delete(game)
                            }
                            authModel.saveUserModel(model) { _ in
                                authModel.setRawAppleId(nil)
                            }
                        }
                    case .failure(let err):
                        botMessage = err.localizedDescription
                        isRed = true
                    }
                    showAppleDeleteConfirmation = false
                }
            }
        }
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = reauthCoordinator
        controller.presentationContextProvider = reauthCoordinator
        controller.performRequests()
    }
}


