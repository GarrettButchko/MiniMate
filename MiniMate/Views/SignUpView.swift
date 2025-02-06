//
//  SingUpView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//


import SwiftUI

struct SignUpView: View {
    @StateObject var authViewModel: AuthViewModel
    @StateObject var viewManager: ViewManager
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            
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
            
            Button("Sign Up") {
                
                authViewModel.createUser(email: email, password: password) { result in
                    switch result {
                    case .success(let user):
                        errorMessage = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Slight delay to ensure user is set
                            authViewModel.saveUserData(key: "name", data: name) { success in
                                if success {
                                    withAnimation {
                                        viewManager.navigateToMain()
                                    }
                                } else {
                                    errorMessage = "Failed to save user data."
                                }
                            }
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }

                
                
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
