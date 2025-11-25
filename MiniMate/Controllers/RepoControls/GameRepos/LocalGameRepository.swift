//
//  LocalGameRepository.swift
//  MiniMate
//
//  Created by Garrett Butchko on 11/24/25.
//

import SwiftData
import Foundation

class LocalGameRepository: GameRepository {
    let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func save(_ game: Game, completion: @escaping (Bool) -> Void) {
        context.insert(game)
        do {
            try context.save()
            completion(true)
        } catch {
            print("❌ Failed to save locally:", error)
            completion(false)
        }
    }
    
    func fetch(id: String, completion: @escaping (Game?) -> Void) {
        do {
            let descriptor = FetchDescriptor<Game>(predicate: #Predicate { $0.id == id })
            let results = try context.fetch(descriptor)
            completion(results.first)
        } catch {
            print("❌ Failed to fetch locally by id:", error)
            completion(nil)
        }
    }
    
    func fetchAll(completion: @escaping ([Game]) -> Void) {
        do {
            let descriptor = FetchDescriptor<Game>()
            let all = try context.fetch(descriptor)
            completion(all)
        } catch {
            print("❌ Failed to fetch all locally:", error)
            completion([])
        }
    }
    
    func fetchAll(ids: [String], completion: @escaping ([Game]) -> Void) {
        do {
            // Create a predicate matching IDs in the array
            let predicate = #Predicate<Game> { game in
                ids.contains(game.id)
            }

            // Attach the predicate to the FetchDescriptor
            var descriptor = FetchDescriptor<Game>(predicate: predicate)

            let results = try context.fetch(descriptor)
            completion(results)

        } catch {
            print("❌ Failed to fetch with IDs:", error)
            completion([])
        }
    }

    
    func delete(id: String, completion: @escaping (Bool) -> Void) {
        do {
            let descriptor = FetchDescriptor<Game>(predicate: #Predicate { $0.id == id })
            if let game = try context.fetch(descriptor).first {
                context.delete(game)
                try context.save()
                completion(true)
            } else {
                completion(false)
            }
        } catch {
            print("❌ Failed to delete locally:", error)
            completion(false)
        }
    }
    
    func deleteAll(ids: [String], completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var success = true

        for id in ids {
            group.enter()
            self.delete(id: id) { didDelete in
                if !didDelete { success = false }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(success)
        }
    }
}
