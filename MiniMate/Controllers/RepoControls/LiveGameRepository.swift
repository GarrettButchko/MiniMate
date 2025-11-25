//
//  LiveGameRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//

import Foundation
import FirebaseDatabase

/// Handles Realtime Database operations for Game objects
final class LiveGameRepository {
    
    private let dbRef = Database.database().reference().child("live_games")
    
    // MARK: - Add or Update Game
    func addOrUpdateGame(_ game: Game, completion: @escaping (Bool) -> Void) {
        let ref = dbRef.child(game.id)
        let dto = game.toDTO()
        
        do {
            let data = try JSONEncoder().encode(dto)
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                ref.setValue(dict) { error, _ in
                    DispatchQueue.main.async {
                        completion(error == nil)
                    }
                }
            }
        } catch {
            print("❌ Encoding game error: \(error.localizedDescription)")
            DispatchQueue.main.async { completion(false) }
        }
    }
    
    // MARK: - Fetch Game by ID
    func fetchGame(id: String, completion: @escaping (Game?) -> Void) {
        let ref = dbRef.child(id)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value)
                let dto = try JSONDecoder().decode(GameDTO.self, from: jsonData)
                let model = Game.fromDTO(dto)
                DispatchQueue.main.async { completion(model) }
            } catch {
                print("❌ Decoding game error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
    
    // MARK: - Delete Game
    func deleteGame(id: String, completion: @escaping (Bool) -> Void) {
        dbRef.child(id).removeValue { error, _ in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
    
    
}
