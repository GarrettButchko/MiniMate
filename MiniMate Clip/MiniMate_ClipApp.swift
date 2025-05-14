//
//  MiniMate_ClipApp.swift
//  MiniMate Clip
//
//  Created by Garrett Butchko on 5/12/25.
//

import SwiftUI
import SwiftData

@main
struct MiniMate_ClipApp: App {
    // Replace default model container with App Group–based one
        private var sharedContainer: ModelContainer = {
            let appGroupID = "group.com.circuit-leaf.mini-mate" // Match what you set in Xcode
            let sharedURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
                .appendingPathComponent("SharedSwiftData")

            let config = ModelConfiguration(url: sharedURL)

            return try! ModelContainer(
                for: UserModel.self, Player.self, Game.self, Hole.self,
                configurations: config
            )
        }()
    
    var body: some Scene {
        WindowGroup {
            ContentViewClip()
        }
        .modelContainer(sharedContainer)
    }
}
