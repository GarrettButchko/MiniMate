// AuthViewModel.swift
// MiniMate
//
// Updated to use UserModel and Game from SwiftData models

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore
import FirebaseStorage
import SwiftData
import AuthenticationServices
import CryptoKit
/// ViewModel that manages Firebase Authentication and app-specific user data
class AuthViewModel: ObservableObject {
    /// The currently authenticated Firebase user
    @Published var firebaseUser: FirebaseAuth.User?
    /// The user's app-specific data model
    @Published var userModel: UserModel?
    
    var currentNonce: String?
    /// The true Apple “user” string, exactly what Apple gives you.
    // ★ persist this across launches
    private(set) var rawAppleUserID: String? {
        didSet {
            UserDefaults.standard.set(rawAppleUserID, forKey: "rawAppleUserID")
        }
    }
    /// A sanitized version you can safely use as a Firebase key.
    var appleUserID: String? {
        rawAppleUserID?
            .replacingOccurrences(of: ".", with: "")  // replace illegal chars
            .replacingOccurrences(of: "$", with: "")
    }
    
    /// The key we use for all our DB reads/writes.
    var currentUserIdentifier: String {
        appleUserID ?? firebaseUser?.uid ?? "IDGuest"
    }
    
    private let loc = LocFuncs()
    
    init() {
        self.firebaseUser = Auth.auth().currentUser
        self.rawAppleUserID = UserDefaults.standard.string(forKey: "rawAppleUserID")
    }
    
    // MARK: - Firebase Authentication
    
    func setRawAppleId(_ rawAppleUserID: String?) {
        self.rawAppleUserID = rawAppleUserID
    }
    
    /// Attempts to load the UserModel from SwiftData or Realtime DB, creating it if missing.
    /// - Parameters:
    ///   - user:       an optional freshly-signed-in Firebase `User` (e.g. after Apple sign-in)
    ///   - name:       an optional “preferred” name to use if we have to create the record
    ///   - context:    the SwiftData `ModelContext` for local persistence
    ///   - completion: called on the main thread as soon as `self.userModel` is set
    func loadOrCreateUserIfNeeded(
        user: User? = nil,
        name: String? = nil,
        in context: ModelContext,
        completion: @escaping () -> Void
    ) {
        print("🔹 loadOrCreateUserIfNeeded called")

        let firebaseUser = user ?? Auth.auth().currentUser
        let gameRepo = UnifiedGameRepository(context: context)

        // 1️⃣ Try local first
        if let local = loc.fetchUser(by: currentUserIdentifier, context: context) {
            print("✅ Loaded local user: \(local.name)")
            self.userModel = local
            
            gameRepo.saveAllLocally(local.gameIDs, context: context) { _ in
                completion()
            }
            return
        }

        print("⚠️ No local user found → checking Firestore")

        // 2️⃣ Try Firestore next
        fetchUserModel(id: currentUserIdentifier) { [weak self] remote in
            guard let self else { return }

            if let remote = remote {
                print("🔹 Found remote user: \(remote.name) — saving locally")

                context.insert(remote)
                try? context.save()

                self.userModel = remote

                gameRepo.saveAllLocally(remote.gameIDs, context: context) { _ in
                    completion()
                }
                return
            }

            // 3️⃣ No user anywhere → Create new user
            print("🆕 Creating brand new user...")

            let finalName  = name ?? firebaseUser?.displayName ?? "Error"
            let finalEmail = firebaseUser?.email ?? "Error"

            let newUser = UserModel(
                id: currentUserIdentifier,
                name: finalName,
                photoURL: firebaseUser?.photoURL,
                email: finalEmail,
                gameIDs: []
            )

            context.insert(newUser)
            try? context.save()

            print("🔹 Saving new user to Firestore...")
            self.saveUserModel(newUser) { _ in
                self.userModel = newUser
                completion()
            }
        }
    }

    /// Generates a random alphanumeric nonce of the given length.
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            // 16 bytes at a time
            let randoms = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randoms.forEach { byte in
                if remainingLength == 0 { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    /// Hashes input with SHA256 and returns the hex string.
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    func signInWithApple(_ authorization: ASAuthorization, context: ModelContext, completion: @escaping (Result<User, Error>, String?) -> Void) {
        // 1️⃣ Extract the Apple credential + nonce
        guard
            let cred      = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce     = currentNonce,
            let tokenData = cred.identityToken,
            let idToken   = String(data: tokenData, encoding: .utf8)
        else {
            return completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential"]
            )), nil)
        }
        
        // 2️⃣ Build the OAuth credential & sign in
        let accessToken = cred.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
        let oauthCred = OAuthProvider.credential(
            providerID: .apple,
            idToken:    idToken,
            rawNonce:   nonce,
            accessToken: accessToken
        )
        
        Auth.auth().signIn(with: oauthCred) { [self] authResult, error in
            if let error = error {
                return completion(.failure(error), nil)
            }
            if let result = authResult {
                rawAppleUserID = cred.user
                updateDisplayName(to: (cred.fullName?.formatted())!) { error in
                    if error != nil {
                        print("Error")
                    } else {
                        print("Successfully")
                    }
                }
                completion(.success(result.user), cred.fullName?.formatted())
            }
        }
    }
    
    func uploadProfilePhoto(
        _ image: UIImage,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let user = firebaseUser else {
            return completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No signed-in user"]
            )))
        }
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Image conversion failed"]
            )))
        }
        
        let key = currentUserIdentifier
        let ref = Storage.storage()
            .reference()
            .child("profile_pictures")
            .child("\(key).jpg")
        
        // 1️⃣ upload
        ref.putData(data, metadata: nil) { meta, error in
            if let error = error {
                return completion(.failure(error))
            }
            // 2️⃣ get download URL
            ref.downloadURL { result in
                switch result {
                case .failure(let error):
                    return completion(.failure(error))
                case .success(let url):
                    // 3️⃣ update Firebase Auth
                    let changeReq = user.createProfileChangeRequest()
                    changeReq.photoURL = url
                    changeReq.commitChanges { err in
                        if let err = err {
                            print("⚠️ Failed to set Auth photoURL:", err)
                            // we'll still proceed to save to DB though
                        }
                        
                        // 4️⃣ Update your UserModel and Realtime DB
                        DispatchQueue.main.async {
                            // update SwiftData model
                            if let local = self.userModel {
                                local.photoURL = url
                            }
                            
                            // push to Realtime DB
                            if let model = self.userModel {
                                model.photoURL = url
                                self.saveUserModel(model) { _ in
                                    // 5️⃣ return URL in completion
                                    completion(.success(url))
                                }
                            } else {
                                completion(.success(url))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func uploadCompanyImages(_ image: UIImage, id: String, key: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let data = image.pngData() else {
            return completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Image conversion failed"]
            )))
        }
        
        let ref = Storage.storage()
            .reference()
            .child(id)
            .child("\(key).png")
        
        // 1️⃣ upload
        ref.putData(data, metadata: nil) { meta, error in
            if let error = error {
                return completion(.failure(error))
            }
            // 2️⃣ get download URL
            ref.downloadURL { result in
                switch result {
                case .failure(let error):
                    return completion(.failure(error))
                case .success(let url):
                    // 3️⃣ update Firebase Auth
                    completion(.success(url))
                }
            }
        }
    }
    
    /// Signs in the user using Google Sign-In and Firebase
    func signInWithGoogle(context: ModelContext, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
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
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
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
                    return completion(.failure(error))
                }
                if let result = authResult {
                    completion(.success(result.user))
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
                if self.appleUserID != nil {
                    self.rawAppleUserID = nil
                }
            }
        } catch {
            print("❌ Sign-out error: \(error.localizedDescription)")
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
    
    /// Reauthenticates the current user with Apple credentials, then deletes their account.
    /// - Parameters:
    ///   - authorization: the ASAuthorization returned by your Apple reauth flow
    ///   - completion: called with success or failure once deletion is done
    func deleteAppleAccount(
        using authorization: ASAuthorization,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // 1️⃣ Extract the AppleID credential & your stored nonce
        guard let appleCred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce     = currentNonce,
              let tokenData = appleCred.identityToken,
              let idToken   = String(data: tokenData, encoding: .utf8)
        else {
            return completion(.failure(NSError(
                domain: "AuthViewModel",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential"]
            )))
        }
        
        // 2️⃣ Build the OAuthProvider credential (no accessToken needed here)
        let oauthCred = OAuthProvider.credential(
            providerID:   .apple,
            idToken:      idToken,
            rawNonce:     nonce,
            accessToken:  nil
        )
        
        // 3️⃣ Call your existing deleteAccount method
        deleteAccount(reauthCredential: oauthCred, completion: completion)
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
    
    
    
    
    func updateDisplayName(to newName: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "Auth", code: -1,
                               userInfo: [NSLocalizedDescriptionKey: "No signed-in user"]))
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newName
        changeRequest.commitChanges { error in
            if let error = error {
                print("❌ Failed to update displayName:", error)
            } else {
                print("✅ displayName updated to:", newName)
            }
            completion(error)
        }
    }
    
    
    // MARK: UserModel
    /// Saves or updates the UserModel in Firestore
    func saveUserModel(_ model: UserModel? = nil, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let uid = currentUserIdentifier
        let ref = db.collection("users").document(uid)
        
        do {
            // Firestore will merge if document exists
            try ref.setData(from: (model != nil ? model!.toDTO() : userModel?.toDTO()), merge: true) { error in
                if let error = error {
                    print("❌ Firestore save error: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        } catch {
            print("❌ Firestore encoding error: \(error)")
            completion(false)
        }
    }
    
    /// Fetchs the UserModel in Firestore
    func fetchUserModel(id: String, completion: @escaping (UserModel?) -> Void) {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(id)
        
        ref.getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore fetch error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            
            do {
                // Decode directly from Firestore document
                let dto = try snapshot.data(as: UserDTO.self)
                let model = UserModel.fromDTO(dto)
                DispatchQueue.main.async { self.userModel = model }
                completion(model)
            } catch {
                print("❌ Firestore decoding error: \(error)")
                completion(nil)
            }
        }
    }
}

