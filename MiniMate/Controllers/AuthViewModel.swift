// AuthViewModel.swift
// MiniMate
//
// Updated to use UserModel and Game from SwiftData models

import Foundation
import FirebaseAuth
import FirebaseDatabase
import GoogleSignIn
import FirebaseCore
import FirebaseStorage
import SwiftData

/// ViewModel that manages Firebase Authentication and app-specific user data
class AuthViewModel: ObservableObject {
    /// The currently authenticated Firebase user
    @Published var firebaseUser: FirebaseAuth.User?
    /// The user's app-specific data model
    @Published var userModel: UserModel?
    private var gameListenerHandle: DatabaseHandle?
    
    private let loc = LocFuncs()

    init() {
        self.firebaseUser = Auth.auth().currentUser
    }

    // MARK: - Firebase Authentication
    
    func loadOrCreateUserIfNeeded(_ context: ModelContext) {
        guard let firebaseUser = Auth.auth().currentUser else {
            print("⚠️ No Firebase user.")
            return
        }

        // Try to load from SwiftData
        if let localUser = loc.fetchUser(by: firebaseUser.uid, context: context) {
            let all = try? context.fetch(FetchDescriptor<UserModel>())
            print("🔍 Total users in store: \(all?.count ?? -1)")
            print("✅ Loaded local user: \(localUser.name)")
            userModel = localUser
        } else {
            print("⚠️ No local user found. Trying Firebase...")

            // Try from Firebase DB
            fetchUserModel(id: firebaseUser.uid) { [self] model in
                if let model = model {
                    context.insert(model)
                    try? context.save()
                    print("✅ Loaded from Firebase and saved locally: \(model.name)")
                    self.userModel = model
                } else {
                    // Create new user if none in Firebase
                    let newUser = UserModel(id: firebaseUser.uid, name: firebaseUser.displayName!, photoURL: firebaseUser.photoURL, email: firebaseUser.email, games: [])
                    context.insert(newUser)
                    try? context.save()
                    saveUserModel(newUser) { _ in }
                    print("🆕 Created and saved new user.")
                    userModel = newUser
                }
            }
        }
    }

    /// Signs in the user using Google Sign-In and Firebase
    func signInWithGoogle(completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Firebase client ID"])))
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
                .first else {
            completion(.failure(NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to access rootViewController"])))
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] signInResult, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google ID token missing"])))
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error)); return
                }
                if let firebaseUser = authResult?.user {
                    DispatchQueue.main.async { self?.firebaseUser = firebaseUser }
                    completion(.success(firebaseUser))
                }
            }
        }
    }

    /// Creates a new user with email and password
    func createUser(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error)); return
            }
            if let firebaseUser = result?.user {
                DispatchQueue.main.async { self?.firebaseUser = firebaseUser }
                completion(.success(firebaseUser))
            }
        }
    }

    /// Signs in an existing user with email and password
    func signIn(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error)); return
            }
            if let firebaseUser = result?.user {
                DispatchQueue.main.async { self?.firebaseUser = firebaseUser }
                completion(.success(firebaseUser))
            }
        }
    }

    /// Signs out the current user
    func logout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.firebaseUser = nil
                self.userModel = nil
            }
        } catch {
            print("❌ Sign-out error: \(error.localizedDescription)")
        }
    }

    // MARK: - App Data Persistence

    /// Saves or updates the UserModel in Realtime Database
    func saveUserModel(_ model: UserModel, completion: @escaping (Bool) -> Void) {
        guard let uid = firebaseUser?.uid else {
            completion(false); return
        }
        let ref = Database.database().reference().child("users").child(uid)
        let dto = model.toDTO()
        do {
            let data = try JSONEncoder().encode(dto)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                ref.setValue(dict) { error, _ in
                    completion(error == nil)
                }
            }
        } catch {
            print("❌ Encoding error: \(error.localizedDescription)")
            completion(false)
        }
    }

    /// Fetches UserModel by ID
    func fetchUserModel(id: String, completion: @escaping (UserModel?) -> Void) {
        let ref = Database.database().reference().child("users").child(id)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else { completion(nil); return }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let dto = try JSONDecoder().decode(UserDTO.self, from: jsonData)
                let model = UserModel.fromDTO(dto)
                DispatchQueue.main.async { self.userModel = model }
                completion(model)
            } catch {
                print("❌ Decoding error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    

    /// Adds or updates a Game in Realtime Database
    func addOrUpdateGame(_ game: Game, completion: @escaping (Bool) -> Void) {
        let ref = Database.database().reference().child("games").child(game.id)
        let dto = game.toDTO()
        do {
            let data = try JSONEncoder().encode(dto)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                ref.setValue(dict) { error, _ in
                    completion(error == nil)
                }
            }
        } catch {
            print("❌ Encoding game error: \(error.localizedDescription)")
            completion(false)
        }
    }

    /// Fetches a Game by code once
    func fetchGame(id: String, completion: @escaping (Game?) -> Void) {
        let ref = Database.database().reference().child("games").child(id)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value is [String: Any] else { completion(nil); return }
            do {
                let dto = try snapshot.data(as: GameDTO.self)
                let model = Game.fromDTO(dto)
                completion(model)
            } catch {
                print("❌ Decoding game error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    /// Listens for real-time Game updates
    func listenForGameUpdates(id: String, onUpdate: @escaping (Game?) -> Void) {
        let ref = Database.database().reference()
                        .child("games")
                        .child(id)
        // keep the handle around if you need to remove it later
        gameListenerHandle = ref.observe(.value) { snapshot in
            // 1) if there’s simply no node at that path, bail out with nil
            guard snapshot.exists() else {
                DispatchQueue.main.async { onUpdate(nil) }
                return
            }

            // 2) try to decode your DTO; if it fails, send nil
            do {
                // if you’re using the FirebaseDatabaseSwift helper
                let dto: GameDTO? = try snapshot.data(as: GameDTO.self)
                if let dto = dto {
                    let model = Game.fromDTO(dto)
                    DispatchQueue.main.async { onUpdate(model) }
                } else {
                    // decode succeeded but data was empty/malformed
                    DispatchQueue.main.async { onUpdate(nil) }
                }
            } catch {
                print("❌ Real-time decode error:", error)
                DispatchQueue.main.async { onUpdate(nil) }
            }
        }
    }

    /// Stops listening for Game updates
    func stopListeningForGameUpdates(id: String) {
        if let handle = gameListenerHandle {
            let ref = Database.database().reference().child("games").child(id)
            ref.removeObserver(withHandle: handle)
            gameListenerHandle = nil
        }
    }

    /// Deletes the user's account after reauthentication
    func deleteAccount(reauthCredential: AuthCredential, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No signed-in user"])))
            return
        }
        user.reauthenticate(with: reauthCredential) { _, error in
            if let error = error {
                completion(.failure(error)); return
            }
            user.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    DispatchQueue.main.async { self.firebaseUser = nil; self.userModel = nil }
                    completion(.success(()))
                }
            }
        }
    }

    /// Reauthenticate a Google user and hand back the `AuthCredential`
    func reauthenticateWithGoogle(completion: @escaping (Result<AuthCredential, Error>) -> Void) {
      guard let clientID = FirebaseApp.app()?.options.clientID else {
        completion(.failure(NSError(
          domain: "AuthViewModel",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Missing Firebase client ID"]
        )))
        return
      }

      let config = GIDConfiguration(clientID: clientID)
      GIDSignIn.sharedInstance.configuration = config

      guard let rootVC = UIApplication.shared.connectedScenes
              .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
              .first
      else {
        completion(.failure(NSError(
          domain: "AuthViewModel",
          code: -1,
          userInfo: [NSLocalizedDescriptionKey: "Unable to access rootViewController"]
        )))
        return
      }

      GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
        if let error = error {
          completion(.failure(error))
          return
        }
        guard
          let user    = signInResult?.user,
          let idToken = user.idToken?.tokenString
        else {
          completion(.failure(NSError(
            domain: "AuthViewModel",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Google re-authentication failed"]
          )))
          return
        }

        // `tokenString` on `accessToken` is non-optional, so just grab it directly:
        let accessToken = user.accessToken.tokenString

        let credential = GoogleAuthProvider.credential(
          withIDToken:    idToken,
          accessToken:    accessToken
        )
        completion(.success(credential))
      }
    }


    /// Deletes a Game from Realtime Database
    func deleteGame(id: String, completion: @escaping (Bool) -> Void) {
        let ref = Database.database().reference().child("games").child(id)
        ref.removeValue { error, _ in
            completion(error == nil)
        }
    }
}
