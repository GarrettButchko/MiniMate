//
//  LoginView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/7/25.
//

import SwiftUI
import FirebaseAuth
import _AuthenticationServices_SwiftUI

/// Login screen allowing existing users to sign in with email or Google
struct LoginView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    
    /// Local database helper
    let locFuncs = LocFuncs()
    
    /// Error message displayed to the user
    @State private var errorMessage: String?
    
    @State var email: String = ""
    @State var password: String = ""
    
    @State var errorRed : Bool = true
    
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
                            .fill(.ultraThinMaterial) // Light background
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(.ultraThickMaterial)
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
                            .fill(.ultraThinMaterial) // Light background
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(.ultraThickMaterial)
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
                VStack(spacing: 16) {
                    // Google Sign-In Button
                    
                    // Email/Password Login Button
                    Button {
                        authModel.signIn(email: email, password: password) { result in
                            switch result {
                            case .success(let firebaseUser):
                                errorMessage = nil
                                /// If user is in local storage
                                authModel.loadOrCreateUserIfNeeded(user: firebaseUser, name: email, in: context) {
                                    viewManager.navigateToMain(1)
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
                
                Text("or")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack{
                    
                    Button {
                        authModel.signInWithGoogle(context: context) { result in
                            switch result {
                            case .success(let firebaseUser):
                                errorMessage = nil
                                /// If user is in local storage
                                authModel.loadOrCreateUserIfNeeded(user: firebaseUser, in: context) {
                                    viewManager.navigateToMain(1)
                                }
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                          }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .frame(height: 50)
                                .foregroundStyle(.ultraThinMaterial)
                            HStack{
                                Image("google")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Sign in with Google")
                                    .foregroundStyle(.mainOpp)
                                    .font(.caption)
                            }
                            
                        }
                    }
                    
                    SignInWithAppleButton { request in
                        authModel.handleSignInWithAppleRequest(request)
                    } onCompletion: { result in
                        switch result {
                        case .failure(let err):
                            errorMessage = err.localizedDescription
                            
                        case .success(let authorization):
                            authModel.signInWithApple(authorization, context: context) { signInResult, name in
                                switch signInResult {
                                case .failure(let err):
                                    errorMessage = err.localizedDescription
                                    
                                case .success(let firebaseUser):
                                    errorMessage = nil
                                    authModel.loadOrCreateUserIfNeeded(user: firebaseUser, name: name, in: context) {
                                        viewManager.navigateToMain(1)
                                    }
                                }
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                    .frame(height: 50)
                    .cornerRadius(25)
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
