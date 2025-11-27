//
//  RemoteGameRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//
import Foundation
import FirebaseFirestore

class FirestoreGameRepository {
    
    private let db = Firestore.firestore()
    
    // Save or update a game in Firestore
    func save(_ game: Game, completion: @escaping (Bool) -> Void) {
        do {
            try db.collection("games").document(game.id).setData(from: game.toDTO(), merge: true) { error in
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
    
    // Fetch a single game by ID
    func fetch(id: String, completion: @escaping (GameDTO?) -> Void) {
        let ref = db.collection("games").document(id)
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
                let game = try snapshot.data(as: GameDTO.self)
                completion(game)
            } catch {
                print("❌ Firestore decoding error: \(error)")
                completion(nil)
            }
        }
    }
    
    func fetchAll(withIDs ids: [String], completion: @escaping ([GameDTO]) -> Void) {
        guard !ids.isEmpty else {
            completion([])
            return
        }

        // Firestore 'in' queries max 10 items → chunk them
        let chunks = stride(from: 0, to: ids.count, by: 10).map {
            Array(ids[$0..<min($0 + 10, ids.count)])
        }

        var allGames: [String: GameDTO] = [:]
        var remaining = chunks.count

        for chunk in chunks {
            db.collection("games")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snapshot, error in
                    
                    if let error = error {
                        print("❌ Firestore fetchAll chunk error: \(error.localizedDescription)")
                    }

                    guard let docs = snapshot?.documents else {
                        finishIfDone()
                        return
                    }

                    for doc in docs {
                        do {
                            let dto = try doc.data(as: GameDTO.self)
                            allGames[dto.id] = dto
                        } catch {
                            print("❌ Firestore decoding error for id \(doc.documentID): \(error)")
                        }
                    }

                    finishIfDone()
                }
        }

        // Helper to track when all chunks are done
        func finishIfDone() {
            remaining -= 1
            if remaining == 0 {
                // Reorder results in the same order as ids
                let ordered = ids.compactMap { allGames[$0] }
                completion(ordered)
            }
        }
    }



    
    // Delete a game by ID
    func delete(id: String, completion: @escaping (Bool) -> Void) {
        db.collection("games").document(id).delete { error in
            if let error = error {
                print("❌ Firestore delete error: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}
