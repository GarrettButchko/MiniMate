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
                VStack(alignment: .leading) {
                    Text("Email")
                        .foregroundStyle(.secondary)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(lineWidth: 1)
                            .frame(height: 50)
                            .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(.secondary)
                            TextField("example@example", text: $email)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding(.trailing, 5)
                        }
                        .padding(.leading)
                    }
                }

                // Password Field
                VStack(alignment: .leading) {
                    Text("Password")
                        .foregroundStyle(.secondary)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(lineWidth: 1)
                            .frame(height: 50)
                            .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: "lock")
                                .foregroundStyle(.secondary)
                            SecureField("abc123", text: $password)
                                .padding(.trailing, 5)
                        }
                        .padding(.leading, 20)
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
                                        
                                        authModel.fetchUserData { model in
                                            /// if user is in online storage
                                            if let model = model {
                                                userModel = model
                                            /// if user is not in either online storage or local
                                            } else {
                                                let newUser = UserModel(id: user.uid, name: name, email: email, password: "google", games: [])
                                                userModel = newUser
                                                authModel.saveUserData(user: userModel!) { _ in }
                                            }
                                        }
                                        viewManager.navigateToMain()
                                        context.insert(userModel!)
                                    }
                                    viewManager.navigateToMain()
                                } else {
                                    errorMessage = "Missing Google account information."
                                }

                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
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
                                if let existingUser = locFuncs.fetchUser(by: user.uid, context: context) {
                                    userModel = existingUser
                                    authModel.saveUserData(user: userModel!) { _ in }
                                    viewManager.navigateToMain()
                                } else {
                                    authModel.fetchUserData { model in
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
                            RoundedRectangle(cornerRadius: 8)
                                .frame(width: 150, height: 50)
                            Text("Login")
                                .foregroundStyle(.white)
                        }
                    }
                }

                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
            }

            Spacer()

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
