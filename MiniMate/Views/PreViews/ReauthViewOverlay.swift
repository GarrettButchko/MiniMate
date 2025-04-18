//
//  ReauthViewOverlay.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/7/25.
//

import SwiftUI
import FirebaseAuth

/// Overlay login screen for account reauthentication before deletion
struct ReauthViewOverlay: View {
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthModel
    
    @State private var errorMessage: String?
    @State var email: String = ""
    @State var password: String = ""
    @Binding var showLoginOverlay: Bool
    
    let sectionSpacing: CGFloat = 30
    let verticalSpacing: CGFloat = 20

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.01)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    withAnimation{
                        showLoginOverlay = false
                    }
                } // disables tap-out

            // Centered dialog box
            VStack(spacing: verticalSpacing) {
                Text("Reauthenticate")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Enter your account details to delete your account.")
                    .font(.caption)

                // Email Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                        TextField("example@example", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }

                // Password Field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        SecureField("••••••••", text: $password)
                    }
                    .padding()
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }


                // Reauthenticate Button
                Button {
                    authModel.deleteAccount(email: email, password: password) { message in
                        if message == "true" {
                            withAnimation {
                                showLoginOverlay = false
                            }
                        } else {
                            errorMessage = message
                        }
                    }
                } label: {
                    Text("Confirm Deletion")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(maxWidth: 350)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding()
        }
        .ignoresSafeArea(.all)
        .zIndex(1000)
    }
}
