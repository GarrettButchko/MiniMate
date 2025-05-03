// SignUpView.swift
// MiniMate
//
// Refactored to use AuthViewModel and UserModel

import SwiftUI
import FirebaseAuth

/// View for new users to sign up and create an account
struct SignUpView: View {
    @Environment(\.modelContext) private var context

    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    @FocusState private var isTextFieldFocused: Bool

    private let characterLimit = 15

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                Spacer()
                // Title
                VStack(spacing: 8) {
                    HStack {
                        Text("Sign Up")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                    HStack {
                        Text("New users sign up here.")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                Spacer()

                // Form Fields
                VStack(spacing: 20) {
                    // Email Field
                    VStack(alignment: .leading) {
                        Text("Email")
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                            TextField("example@example", text: $email)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .focused($isTextFieldFocused)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 25)
                            .stroke(.ultraThickMaterial))
                    }

                    // Password + Confirm
                    HStack(spacing: 12) {
                        passwordField(title: "Password", text: $password)
                        passwordField(title: "Confirm", text: $confirmPassword)
                    }

                    // Sign Up Button
                    Button(action: signUp) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .frame(width: 150, height: 50)
                                .foregroundColor(.accentColor)
                            Text("Sign Up")
                                .foregroundColor(.white)
                        }
                    }

                    // Error
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                Spacer()
                Spacer()
            }
            .padding()

            // Back Button
            HStack {
                Button(action: {
                    isTextFieldFocused = false
                    withAnimation { viewManager.navigateToLogin() }
                }) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "arrow.left")
                                .font(.headline)
                        )
                }
                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func passwordField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundColor(.secondary)
            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.secondary)
                SecureField("••••••", text: text)
                    .focused($isTextFieldFocused)
                    .onChange(of: text.wrappedValue) { _ , newValue in
                        if newValue.count > characterLimit {
                            text.wrappedValue = String(newValue.prefix(characterLimit))
                        }
                    }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 25)
                .stroke(.ultraThickMaterial))
        }
    }

    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        authModel.createUser(email: email, password: password) { result in
            switch result {
            case .success(let user):
                errorMessage = nil
                // Create app-specific user model
                let newUser = UserModel(
                    id: user.uid,
                    name: email,
                    email: email,
                    games: []
                )
                authModel.userModel = newUser
                context.insert(newUser)
                authModel.saveUserModel(newUser) { _ in }
                viewManager.navigateToMain(1)
                user.sendEmailVerification { _ in }

            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
