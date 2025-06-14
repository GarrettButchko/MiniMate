// AuthViewModel.swift
// MiniMate
//
// Updated to use UserModel and Game from SwiftData models

import Foundation
import SwiftData
import FirebaseDatabase

/// ViewModel that manages Firebase Authentication and app-specific user data
class AuthViewModelClip: ObservableObject, AuthViewManager {
    /// Adds or updates a Course in Realtime Database
    func addOrUpdateCourse(_ course: Course, completion: @escaping (Bool) -> Void) {
        let ref = Database.database().reference().child("courses").child(course.id)
        do {
            let data = try JSONEncoder().encode(course)
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
    func fetchCourse(id: String, completion: @escaping (Course?) -> Void) {
        let ref = Database.database().reference().child("courses").child(id)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                completion(nil)
                return
            }

            do {
                let data = try JSONSerialization.data(withJSONObject: value)
                let course = try JSONDecoder().decode(Course.self, from: data)
                completion(course)
            } catch {
                print("❌ Decoding course error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    
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
    var currentUserIdentifier: String? {
        appleUserID ?? "IDGuest"
    }
    
    private let loc = LocFuncs()
    
    init() {
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
        name: String? = nil,
        in context: ModelContext,
        completion: @escaping () -> Void
    ) {
        
        // 2️⃣ Figure out which key we’re using (Apple ID or Firebase UID)
        guard let uid = currentUserIdentifier else {
            completion()
            return
        }

        // 3️⃣ Try local first
        if let local = loc.fetchUser(by: uid, context: context) {
            print("✅ Loaded local user: \(local.name)")
            self.userModel = local
            completion()    // ← DONE
        } else {
            
            let guest = "Guest" + String(Int.random(in: 10000...99999))
                    // 🚀 Doesn’t exist anywhere → create new
                    let finalName  = name ?? guest
                    let finalEmail = "guest@guest.mail"
                    let newUser = UserModel(
                        id:       finalName != guest ? uid : "IDGuest",
                        name:     finalName,
                        photoURL: nil,
                        email:    finalEmail,
                        games:    []
                    )
                    // Insert locally
                    context.insert(newUser)
                    try? context.save()
                    // Persist remotely
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

