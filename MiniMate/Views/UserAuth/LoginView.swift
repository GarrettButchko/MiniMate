//
//  LoginView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//


import SwiftUI

struct LoginView: View {
    @StateObject var authViewModel: AuthViewModel
    @StateObject var viewManager: ViewManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button("Login") {
                authViewModel.signIn(email: email, password: password) { result in
                    switch result {
                    case .success:
                        errorMessage = nil
                        withAnimation(){
                            viewManager.navigateToMain()
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Login with Google") {
                authViewModel.signInWithGoogle { result in
                    switch result {
                    case .success:
                        errorMessage = nil
                        withAnimation(){
                            viewManager.navigateToMain()
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Sign Up") {
                withAnimation(){
                    viewManager.navigateToSignUp()
                }
    
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("Firebase Auth")
    }
}

