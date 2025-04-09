//
//  LoginView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/7/25.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    
    @StateObject var userData: AuthViewModel
    @StateObject var viewManager: ViewManager

    @State private var errorMessage: String?

    let sectionSpacing: CGFloat = 30
    let verticalSpacing: CGFloat = 20
    
    @State var email: String = ""
    @State var password: String = ""

    var body: some View {
        VStack {
            Spacer()

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
                        }
                        .padding(.leading)
                    }
                }

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
                        }
                        .padding(.leading, 20)
                    }
                }

                // Buttons
                HStack(spacing: 16) {
                    Button {
                        userData.signInWithGoogle { result in
                            switch result {
                            case .success(let user):
                                    errorMessage = ""
                                    viewManager.navigateToMain()
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

                    Button {
                        userData.signIn(email: email, password: password) { result in
                            switch result {
                            case .success:
                                    errorMessage = ""
                                    viewManager.navigateToMain()
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

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }
            }

            Spacer()

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

