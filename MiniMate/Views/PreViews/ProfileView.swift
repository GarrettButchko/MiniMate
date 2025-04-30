// ProfileView.swift
// MiniMate
//
// Updated to use UserModel and AuthViewModel

import SwiftUI
import FirebaseAuth

/// Displays and allows editing of the current user's profile
struct ProfileView: View {
    @Environment(\.modelContext) private var context

    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthViewModel

    @Binding var isSheetPresent: Bool
    @Binding var showLoginOverlay: Bool

    @State private var editProfile: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    @State private var name: String = ""
    @State private var email: String = ""

    @State private var botMessage: String = ""
    @State private var isRed: Bool = true

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

                            // Only allow edit/reset for non-Google accounts
                            if let firebaseUser = authModel.firebaseUser,
                               !firebaseUser.providerData.contains(where: { $0.providerID == "google.com" }) {
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

                    // Account Management Section
                    Section("Account Management") {
                        Button("Logout") {
                            isSheetPresent = false
                            withAnimation {
                                viewManager.navigateToWelcome()
                            }
                            authModel.logout()
                        }
                        .foregroundColor(.red)

                        Button("Delete Account") {
                            if let firebaseUser = authModel.firebaseUser,
                               firebaseUser.providerData.contains(where: { $0.providerID == "google.com" }) {
                                showDeleteConfirmation = true
                            } else {
                                withAnimation {
                                    showLoginOverlay = true
                                }
                            }
                        }
                        .foregroundColor(.red)
                        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
                            Button("Delete", role: .destructive) {
                                authModel.reauthenticateWithGoogle { reauthResult in
                                    switch reauthResult {
                                    case .success(let credential):
                                        authModel.deleteAccount(reauthCredential: credential) { deleteResult in
                                            switch deleteResult {
                                            case .success:
                                                print("✅ Account deleted")
                                                viewManager.navigateToWelcome()
                                            case .failure(let error):
                                                print("❌ Error deleting account: \(error.localizedDescription)")
                                            }
                                        }
                                    case .failure(let error):
                                        print("❌ Error reauthenticating: \(error.localizedDescription)")
                                    }
                                }
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
}

// Reusable row for displaying static user info
struct UserInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("\(label):")
            Text(value)
        }
    }
}
