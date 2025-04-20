//
//  AuthViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import GoogleSignIn
import FirebaseCore
import SwiftUICore
import FirebaseStorage

/// ViewModel that manages Firebase Authentication and user-related logic
class AuthModel: ObservableObject {
    /// The currently authenticated Firebase user (if any)
    @Published var user: User?

    /// Initializes by checking if a user is already logged in
    init() {
        self.user = Auth.auth().currentUser
    }

    /// Signs in the user using Google Sign-In and Firebase
    func signInWithGoogle(completion: @escaping (Result<User, Error>) -> Void) {
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Get the root view controller to present Google Sign-In
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
            .first else {
                print("❌ Error: Could not find rootViewController")
                return
        }

        // Start Google Sign-In flow
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [unowned self] result, error in
            if let error = error {
                print("❌ Google Sign-In Error:", error.localizedDescription)
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("❌ Error: Failed to retrieve Google ID token.")
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            // Authenticate with Firebase using Google credentials
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    completion(.failure(error))
                } else if let user = result?.user {
                    DispatchQueue.main.async {
                        self.user = user
                    }
                    completion(.success(user))
                }
            }
        }
    }

    /// Creates a new user with email and password
    func createUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            /// if theres an error sends failure
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                DispatchQueue.main.async {
                    self.user = user
                }
                completion(.success(user))
            }
        }
    }

    /// Signs in an existing user with email and password
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                DispatchQueue.main.async {
                    self.user = user
                }
                completion(.success(user))
            }
        }
    }

    /// Saves a UserModel to Firebase Realtime Database
    func saveUserData(user: UserModel, completion: @escaping (Bool) -> Void) {
        let ref = Database.database().reference()

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        do {
            let data = try JSONEncoder().encode(user)
            let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            ref.child("users").child(userId).setValue(dictionary) { error, _ in
                completion(error == nil)
            }
        } catch {
            print("❌ Error encoding user data: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    /// Saves a UserModel to Firebase Realtime Database
    func addAndUpdateGame(game: GameModel, completion: @escaping (Bool) -> Void) {
        let ref = Database.database().reference()

        do {
            let data = try JSONEncoder().encode(game)
            let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            ref.child("games").child(game.id).setValue(dictionary) { error, _ in
                completion(error == nil)
            }
        } catch {
            print("❌ Error encoding game data: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func fetchGameData(gameCode: String, completion: @escaping (GameModel?) -> Void) {
        let ref = Database.database().reference()

        ref.child("games").child(gameCode).observeSingleEvent(of: .value) { snapshot, _ in
            guard let data = snapshot.value as? [String: Any] else {
                completion(nil)
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let game = try JSONDecoder().decode(GameModel.self, from: jsonData)
                completion(game)
            } catch {
                print("❌ Error decoding game data: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    /// Fetches a UserModel from Firebase Realtime Database
    func fetchUserData(completion: @escaping (UserModel?) -> Void) {
        let ref = Database.database().reference()

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }

        ref.child("users").child(userId).observeSingleEvent(of: .value) { snapshot, _ in
            guard let data = snapshot.value as? [String: Any] else {
                completion(nil)
                return
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let user = try JSONDecoder().decode(UserModel.self, from: jsonData)
                completion(user)
            } catch {
                print("❌ Error decoding user data: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    /// Signs out the current user
    func logout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.user = nil
            }
        } catch {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
    
    /// Deletes the current user. Handles both Email/Password and Google sign-in methods.
    
        func deleteAccount(email: String? = nil, password: String? = nil, completion: @escaping (String) -> Void) {
            guard let user = Auth.auth().currentUser else {
                completion("❌ No user is currently signed in.")
                return
            }

            if let email = email, let password = password {
                // Reauthenticate using email/password
                let credential = EmailAuthProvider.credential(withEmail: email, password: password)
                user.reauthenticate(with: credential) { result, error in
                    self.handleReauthenticationResult(user: user, error: error, completion: completion)
                }
            } else if let googleUser = GIDSignIn.sharedInstance.currentUser,
                      let idToken = googleUser.idToken?.tokenString {
                
                let accessToken = googleUser.accessToken.tokenString
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                
                user.reauthenticate(with: credential) { result, error in
                    self.handleReauthenticationResult(user: user, error: error, completion: completion)
                }
            } else {
                    guard let clientID = FirebaseApp.app()?.options.clientID else {
                        completion("❌ Missing Firebase client ID.")
                        return
                    }

                    let config = GIDConfiguration(clientID: clientID)
                    GIDSignIn.sharedInstance.configuration = config

                    guard let rootViewController = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
                        .first else {
                            completion("❌ Unable to get rootViewController.")
                            return
                    }

                    GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                        if let error = error {
                            completion("❌ Google Sign-In Error: \(error.localizedDescription)")
                            return
                        }

                        guard let user = result?.user,
                              let idToken = user.idToken?.tokenString else {
                            completion("❌ Failed to retrieve Google ID token.")
                            return
                        }

                        let credential = GoogleAuthProvider.credential(
                            withIDToken: idToken,
                            accessToken: user.accessToken.tokenString
                        )

                        Auth.auth().currentUser?.reauthenticate(with: credential) { result, error in
                            if let currentUser = Auth.auth().currentUser {
                                self.handleReauthenticationResult(user: currentUser, error: error, completion: completion)
                            } else {
                                completion("❌ Firebase user session missing.")
                            }
                        }
                    }
                }
        }

    private func handleReauthenticationResult(user: User, error: Error?, completion: @escaping (String) -> Void) {
        if let error = error {
            let message = "❌ Reauthentication failed: \(error.localizedDescription)"
            print(message)
            completion(message)
            return
        }
        
        user.delete { error in
            if let error = error {
                let message = "❌ Account deletion failed: \(error.localizedDescription)"
                print(message)
                completion(message)
            } else {
                print("✅ Account successfully deleted.")
                DispatchQueue.main.async {
                    self.user = nil
                }
                completion("true")
            }
        }
    }
    func deleteGameData(gameCode: String, completion: @escaping (String?) -> Void) {
        let ref = Database.database().reference()
        ref.child("games").child(gameCode).removeValue { error, _ in
            if let error = error {
                completion("❌ Error deleting data: \(error.localizedDescription)")
            } else {
                completion("✅ Data deleted")
            }
        }
    }
}
