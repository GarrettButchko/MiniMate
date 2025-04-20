//
//  LocFuncs.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/16/25.
//

import SwiftUI
import SwiftData
import Foundation

/// A utility struct for managing local SwiftData operations
struct LocFuncs {
    
    /// Fetches a UserModel from SwiftData using its unique string ID
    /// - Parameters:
    ///   - id: The user ID (usually matches Firebase UID)
    ///   - context: The SwiftData `ModelContext` used to query the store
    /// - Returns: The matching `UserModel` if found, otherwise `nil`
    func fetchUser(by id: String, context: ModelContext) -> UserModel? {
        let predicate = #Predicate<UserModel> { $0.id == id } // ✅ uses stored id
        let descriptor = FetchDescriptor<UserModel>(predicate: predicate)

        do {
            return try context.fetch(descriptor).first
        } catch {
            print("❌ Fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Deletes the local SwiftData SQLite store (dev use only)
    /// Use this for resetting persistent storage (e.g., when schema changes cause migration errors)
    func deletePersistentStore() {
        let fileManager = FileManager.default
        let storeBaseURL = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support")

        let storeFilenames = [
            "default.store",
            "default.store-wal",
            "default.store-shm"
        ]

        for file in storeFilenames {
            let fullPath = storeBaseURL.appendingPathComponent(file)
            if fileManager.fileExists(atPath: fullPath.path) {
                do {
                    try fileManager.removeItem(at: fullPath)
                    print("🗑️ Deleted store file: \(file)")
                } catch {
                    print("❌ Failed to delete \(file): \(error.localizedDescription)")
                }
            }
        }
    }
}
