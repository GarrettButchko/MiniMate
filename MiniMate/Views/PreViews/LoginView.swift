//
//  LoginView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/7/25.
//

import SwiftUI
import FirebaseAuth

/// Login screen allowing existing users to sign in with email or Google
struct LoginView: View {
    @Environment(\.modelContext) private var context
    
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthModel
    
    /// Local database helper
    let locFuncs = LocFuncs()
    
    /// Error message displayed to the user
    @State private var errorMessage: String?
    
    @State var email: String = ""
    @State var password: String = ""
    
    @State var errorRed : Bool = true
    
    /// UserModel binding to sync with app state
    @Binding var userModel: UserModel?

    /// UI constants
    let sectionSpacing: CGFloat = 30
    let verticalSpacing: CGFloat = 20

    var body: some View {
        VStack {
            Spacer()
            
            // MARK: - Title & Description
            VStack(spacing: 8) {
                HStack {
                    Text("Login")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.accent)
                    Spacer()
                }

                HStack {
                    Text("If you are an existing user, please login here.")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(.secondary)
                        .frame(height: 48)
                    Spacer()
                }
            }

            Spacer()

            // MARK: - Email & Password Fields
            VStack(spacing: verticalSpacing) {
                // Email Field
                // Email Field
                VStack(alignment: .leading) {
                    Text("Email")
                        .foregroundStyle(.secondary)

                    ZStack {
                        // Background with light fill
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.mainOpp.opacity(0.15)) // Light background
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.mainOpp.opacity(0.3), lineWidth: 1)
                            )

                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(.secondary)
                            TextField("example@example", text: $email)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding(.trailing, 5)
                        }
                        .padding(.horizontal)
                    }
                }

                // Password Field
                VStack(alignment: .leading) {
                    Text("Password")
                        .foregroundStyle(.secondary)

                    ZStack {
                        // Background with light fill
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.mainOpp.opacity(0.15))
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.mainOpp.opacity(0.3), lineWidth: 1)
                            )

                        HStack {
                            Image(systemName: "lock")
                                .foregroundStyle(.secondary)
                            SecureField("••••••", text: $password)
                                .padding(.trailing, 5)
                        }
                        .padding(.horizontal)
                    }
                }


                // MARK: - Auth Buttons
                HStack(spacing: 16) {
                    // Google Sign-In Button
                    Button {
                        authModel.signInWithGoogle { result in
                            switch result {
                            case .success(let user):
                                errorMessage = nil
                                
                                // Validate Google user info
                                if let name = user.displayName,
                                   let email = user.email {
                                    /// If user is in local storage
                                    if let existingUser = locFuncs.fetchUser(by: user.uid, context: context) {
                                        userModel = existingUser
                                        authModel.saveUserData(user: userModel!) { _ in }
                                        viewManager.navigateToMain()
                                    } else {
                                        
                                        authModel.fetchUserData(id: authModel.user!.uid) { model in
                                            /// if user is in online storage
                                            if let model = model {
                                                userModel = model
                                                context.insert(userModel!)
                                                try? context.save()
                                                viewManager.navigateToMain()
                                            /// if user is not in either online storage or local
                                            } else {
                                                let newUser = UserModel(id: user.uid, mini: UserModelEssentials(id: user.uid, name: name, photoURL: user.photoURL), email: email, games: [])
                                                userModel = newUser
                                                context.insert(userModel!)
                                                try? context.save()
                                                authModel.saveUserData(user: userModel!) { _ in }
                                                viewManager.navigateToMain()
                                            }
                                        }
                                    }
                                } else {
                                    errorRed = true
                                    errorMessage = "Missing Google account information."
                                }

                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .frame(width: 50, height: 50)
                                .foregroundStyle(.ultraThinMaterial)
                            Image("google")
                                .resizable()
                                .frame(width: 30, height: 30)
                        }
                    }

                    // Email/Password Login Button
                    Button {
                        authModel.signIn(email: email, password: password) { result in
                            switch result {
                            case .success(let user):
                                errorMessage = nil
                                /// If user is in local storage
                                if let existingUser = locFuncs.fetchUser(by: user.uid, context: context) {
                                    userModel = existingUser
                                    authModel.saveUserData(user: userModel!) { _ in }
                                    viewManager.navigateToMain()
                                /// if user isn't get from online
                                } else {
                                    authModel.fetchUserData(id: authModel.user!.uid) { model in
                                        if let model = model {
                                            userModel = model
                                            viewManager.navigateToMain()
                                        } else {
                                            fatalError("User Data Not Found!!!!!!")
                                        }
                                    }
                                }

                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .frame(width: 150, height: 50)
                            Text("Login")
                                .foregroundStyle(.white)
                        }
                    }
                }

                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(errorRed ? Color.red : .mainOpp)
                        .font(.caption)
                        .padding(.top, 8)
                }
            }

            Spacer()

            
                
            Button {
                if email != "" {
                    Auth.auth().sendPasswordReset(withEmail: email) { error in
                        if let error = error {
                            errorMessage = error.localizedDescription
                        } else {
                            errorRed = false
                            errorMessage = "Password reset email sent!"
                        }
                    }
                } else {
                    errorRed = true
                    errorMessage = "Please enter your email address"
                }
                
            } label: {
                Text("Reset Password")
            }
            .padding(.bottom, 5)
            
            // MARK: - Navigation to Sign Up
            HStack(spacing: 4) {
                Text("If you are a new user")
                    .foregroundStyle(.secondary)
                Button {
                    withAnimation {
                        viewManager.navigateToSignUp()
                    }
                } label: {
                    Text("sign up here")
                }
            }

            Spacer()
        }
        .padding()
    }
}
