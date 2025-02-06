//
//  AuthViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//


import Foundation
import FirebaseAuth
import FirebaseDatabase

class AuthViewModel: ObservableObject {
    @Published var user: User?

    init() {
        self.user = Auth.auth().currentUser
    }
    
    
    
    func createUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
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
    
    func fetchUserData<T>(key: String, completion: @escaping (T?) -> Void) {
        let ref = Database.database().reference()
        if let userId = user?.uid{
            ref.child("users").child(userId).child(key).observe(.value) { snapshot in
                completion(snapshot.value as? T ?? "N/A" as! T)
            }
        }
    }
    
    func saveUserData<T>(key: String, data: T, completion: @escaping (Bool) -> Void) {
        let ref = Database.database().reference()
        if let userId = user?.uid{
            ref.child("users").child(userId).setValue([key: data]) { error, _ in
                completion(error == nil)
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.user = nil
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
