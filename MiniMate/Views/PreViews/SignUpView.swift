//
//  SignUpView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @Environment(\.modelContext) private var context
    
    @StateObject var viewManager: ViewManager
    @StateObject var authViewModel : AuthModel
    let locFuncs = LocFuncs()
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    
    @Binding var userModel : UserModel?

    @FocusState private var isTextFieldFocused: Bool

    let sectionSpacing: CGFloat = 30
    let verticalSpacing: CGFloat = 20

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                Spacer()

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

                VStack(spacing: verticalSpacing) {
                    
                    
                    
                    // Email
                    VStack {
                        HStack {
                            Text("Email")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(lineWidth: 1)
                                .frame(height: 50)
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundStyle(.secondary)
                                TextField("example@example", text: $email)
                                    .foregroundColor(.secondary)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .padding(.trailing, 5)
                                    .focused($isTextFieldFocused)
                            }
                            .padding(.leading)
                        }
                    }
                    
                    
                    HStack{
                        // Password
                        VStack {
                            HStack {
                                Text("Password")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(lineWidth: 1)
                                    .frame(height: 50)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 5)
                                    SecureField("123ABC", text: $password)
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 5)
                                        .focused($isTextFieldFocused)
                                }
                                .padding(.leading, 20)
                            }
                        }
                        Spacer()
                        // Confirm Password
                        VStack {
                            HStack {
                                Text("Confirm Password")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(lineWidth: 1)
                                    .frame(height: 50)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 5)
                                    SecureField("123ABC", text: $confirmPassword)
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 5)
                                        .focused($isTextFieldFocused)
                                }
                                .padding(.leading, 20)
                            }
                        }
                    }
                    
                    
                    
                    // Sign Up Button
                    Button {
                        if password == confirmPassword {
                            authViewModel.createUser(email: email, password: password) { result in
                                switch result {
                                case .success:
                                        errorMessage = ""
                                    context.insert(UserModel(id: authViewModel.user!.uid, name: email, email: email, password: password, games: []))
                                        viewManager.navigateToMain()
                                case .failure(let error):
                                        errorMessage = error.localizedDescription
                                }
                            }
                        } else {
                            errorMessage = "Passwords do not match."
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .frame(width: 150, height: 50)
                            Text("Sign Up")
                                .foregroundStyle(.white)
                        }
                    }
                    
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

            // Back button
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
                            .frame(width: 30, height: 30)
                            .fontWeight(.bold)
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}

