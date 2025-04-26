//
//  SignUpView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

/// View for new users to sign up and create an account
struct SignUpView: View {
    @Environment(\.modelContext) private var context

    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthModel
    let locFuncs = LocFuncs()

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    /// Stores the created user in local database
    @Binding var userModel: UserModel?

    @FocusState private var isTextFieldFocused: Bool

    let sectionSpacing: CGFloat = 30
    let verticalSpacing: CGFloat = 20
    let characterLimit: Int = 15

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                Spacer()

                // MARK: - Title and Subtitle
                VStack(spacing: 8) {
                    HStack {
                        Text("Sign Up")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.accent)
                        Spacer()
                    }
                    HStack {
                        Text("If you are a new user, please sign up here.")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }

                Spacer()

                // MARK: - Form Fields
                VStack(spacing: verticalSpacing) {
                    // Email Field
                    // Email Field
                    VStack(alignment: .leading) {
                        Text("Email")
                            .foregroundStyle(.secondary)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.mainOpp.opacity(0.15))
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
                                    .focused($isTextFieldFocused)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Password + Confirm Password
                    HStack(alignment: .top, spacing: 12) {
                        // Password
                        VStack(alignment: .leading) {
                            Text("Password")
                                .foregroundStyle(.secondary)
                            
                            ZStack {
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
                                        .focused($isTextFieldFocused)
                                        .onChange(of: password) { newValue, oldValue in
                                            if newValue.count > characterLimit {
                                                password = String(newValue.prefix(characterLimit))
                                            }
                                        }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Confirm Password
                        VStack(alignment: .leading) {
                            Text("Confirm")
                                .foregroundStyle(.secondary)
                            
                            ZStack {
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
                                    SecureField("••••••", text: $confirmPassword)
                                        .padding(.trailing, 5)
                                        .focused($isTextFieldFocused)
                                        .onChange(of: confirmPassword) { newValue, oldValue  in
                                            if newValue.count > characterLimit {
                                                confirmPassword = String(newValue.prefix(characterLimit))
                                            }
                                        }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }


                    // MARK: - Sign Up Button
                    Button {
                        guard password == confirmPassword else {
                            errorMessage = "Passwords do not match."
                            return
                        }
                        
                        authModel.createUser(email: email, password: password) { result in
                            switch result {
                            case .success (let user):
                                errorMessage = nil
                                let newUser = UserModel(id: user.uid, mini: UserModelEssentials(id: user.uid, name: email), email: email, games: [])
                                userModel = newUser
                                context.insert(userModel!)
                                authModel.saveUserData(userModel!) { _ in }
                                viewManager.navigateToMain()
                                Auth.auth().currentUser?.sendEmailVerification { error in
                                    print("Failed to send verification email.")
                                }
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .frame(width: 150, height: 50)
                            Text("Sign Up")
                                .foregroundStyle(.white)
                        }
                    }

                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Spacer()
                Spacer()
            }
            .padding()

            // MARK: - Back Button
            HStack {
                Button {
                    isTextFieldFocused = false
                    withAnimation {
                        viewManager.navigateToLogin()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        Image(systemName: "arrow.left")
                            .fontWeight(.bold)
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}

