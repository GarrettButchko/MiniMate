//
//  UnifiedGameRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//
import SwiftData

class UnifiedGameRepository {
    let local: LocalGameRepository
    let remote = FirestoreGameRepository()
    
    init(context: ModelContext) {
        self.local = LocalGameRepository(context: context)
    }
    
    func save(_ game: Game, completion: @escaping (Bool) -> Void) {
        // 1️⃣ Save locally
        local.save(game) { success in
            if !success { completion(false); return }
            
            // 2️⃣ Save remotely
            self.remote.save(game) { remoteSuccess in
                completion(remoteSuccess)
            }
        }
    }
    
    func fetch(id: String, completion: @escaping (Game?) -> Void) {
        // Try local first
        local.fetch(id: id) { localGame in
            if let game = localGame {
                completion(game)
            } else {
                self.remote.fetch(id: id, completion: completion)
            }
        }
    }
    
    func fetchAll(completion: @escaping ([Game]) -> Void) {
        // Fetch local games first
        local.fetchAll { localGames in
            self.remote.fetchAll { remoteGames in
                // Combine and deduplicate by game.id
                var seenIDs = Set<String>()
                var combined: [Game] = []

                for game in localGames + remoteGames {
                    if !seenIDs.contains(game.id) {
                        combined.append(game)
                        seenIDs.insert(game.id)
                    }
                }

                completion(combined)
            }
        }
    }
    
    func fetchAll(ids: [String], completion: @escaping ([Game]) -> Void) {
        // Fetch local games first
        local.fetchAll(ids: ids) { localGames in
            self.remote.fetchAll(withIDs: ids) { remoteGames in
                // Combine and deduplicate by game.id
                var seenIDs = Set<String>()
                var combined: [Game] = []

                for game in localGames + remoteGames {
                    if !seenIDs.contains(game.id) {
                        combined.append(game)
                        seenIDs.insert(game.id)
                    }
                }

                completion(combined)
            }
        }
    }
}
