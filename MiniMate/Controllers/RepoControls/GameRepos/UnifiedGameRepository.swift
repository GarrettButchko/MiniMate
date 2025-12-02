//
//  UnifiedGameRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//
import SwiftData
import Dispatch

class UnifiedGameRepository {
    let local: LocalGameRepository
    let remote = FirestoreGameRepository()
    
    init(context: ModelContext) {
        self.local = LocalGameRepository(context: context)
    }
    
    func saveAllLocally(_ gameIds: [String], context: ModelContext, completion: @escaping (Bool) -> Void) {
        print("start of save all locally")
        fetchAll(ids: gameIds) { games in
            print("Fetched \(games.count) games")
            for game in games {
                // 2️⃣ Insert only if it's new
                context.insert(Game.fromDTO(game))
                do {
                    try context.save()
                    print("💾 Inserted new game: \(game.id)")
                    completion(true)
                } catch {
                    print("❌ Failed to save locally:", error)
                    completion(false)
                }
            }
        }
    }
    
    func save(_ game: Game, completion: @escaping (Bool, Bool) -> Void) {
        
        var localComplete = false
        var remoteComplete = false
        
        
        // 1️⃣ Save locally
        local.save(game) { success in
            localComplete = success
        }
        // 2️⃣ Save remotely
        remote.save(game) { remoteSuccess in
            remoteComplete = remoteSuccess
        }
        
        completion(localComplete, remoteComplete)
    }
    
    func fetch(id: String, completion: @escaping (GameDTO?) -> Void) {
        // Try local first
        local.fetch(id: id) { localGame in
            if let game = localGame {
                completion(game.toDTO())
            } else {
                self.remote.fetch(id: id, completion: completion)
            }
        }
    }
    
    func fetchAll(ids: [String], completion: @escaping ([GameDTO]) -> Void) {
        // 1️⃣ Fetch local immediately
        local.fetchAll(ids: ids) { localGames in
            
            let localDTOs = localGames.map { $0.toDTO() }
            
            // Begin remote fetch in parallel, but with timeout
            var remoteReturned = false
            var remoteDTOs: [GameDTO] = []
            
            // 2️⃣ Start a timeout timer (e.g., 5 seconds)
            let timeoutSeconds = 5.0
            let timer = DispatchSource.makeTimerSource()
            timer.schedule(deadline: .now() + timeoutSeconds)
            timer.setEventHandler {
                if !remoteReturned {
                    remoteReturned = true
                    timer.cancel()
                    print("⏰ Remote fetch timed out — using local only")
                    finish()
                }
            }
            timer.resume()
            
            // 3️⃣ Remote fetch
            self.remote.fetchAll(withIDs: ids) { fetchedRemote in
                if !remoteReturned {
                    remoteReturned = true
                    timer.cancel()
                    remoteDTOs = fetchedRemote
                    finish()
                }
            }
            
            // 4️⃣ Merge + complete (shared helper)
            func finish() {
                var seen = Set<String>()
                var combined: [GameDTO] = []
                
                for game in localDTOs + remoteDTOs {
                    if seen.insert(game.id).inserted {
                        combined.append(game)
                    }
                }
                
                completion(combined)
            }
        }
    }

}
