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
    func fetch(id: String, completion: @escaping (Game?) -> Void) {
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
                completion(Game.fromDTO(game))
            } catch {
                print("❌ Firestore decoding error: \(error)")
                completion(nil)
            }
        }
    }
    
    // Fetch all games for the current user
    func fetchAll(completion: @escaping ([Game]) -> Void) {
        db.collection("games").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Firestore fetchAll error: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
            let games: [Game] = documents.compactMap { doc in
                try? Game.fromDTO(doc.data(as: GameDTO.self))
                
            }
            completion(games)
        }
    }
    
    func fetchAll(withIDs ids: [String], completion: @escaping ([Game]) -> Void) {
        guard !ids.isEmpty else {
            completion([])
            return
        }
        
        // Break IDs into Firestore-compatible chunks (max 10 per batch)
        let chunks = stride(from: 0, to: ids.count, by: 10).map {
            Array(ids[$0..<min($0 + 10, ids.count)])
        }
        
        var allGames: [Game] = []
        var remainingChunks = chunks.count
        
        for chunk in chunks {
            db.collection("games")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments { snapshot, error in
                    
                    if let error = error {
                        print("❌ Firestore chunk fetch error: \(error.localizedDescription)")
                    }
                    
                    if let documents = snapshot?.documents {
                        let games: [Game] = documents.compactMap { doc in
                            try? Game.fromDTO(doc.data(as: GameDTO.self))
                        }
                        allGames.append(contentsOf: games)
                    }
                    
                    remainingChunks -= 1
                    
                    // Once ALL chunks finish, return results
                    if remainingChunks == 0 {
                        completion(allGames)
                    }
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
