//
//  MiniMateApp.swift
//  MiniMate
//
//  Created by Garrett Butchko on 1/31/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import StoreKit
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        MobileAds.shared.start(completionHandler: nil)
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Local (non-shared) SwiftData container
    private var modelContainer: ModelContainer = {
        // Use a local file URL inside the app's Documents directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storeURL = documentsURL.appendingPathComponent("MiniMate.sqlite")

        let config = ModelConfiguration(url: storeURL)
        return try! ModelContainer(
            for: UserModel.self, Player.self, Game.self, Hole.self,
            configurations: config
        )
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer) // inject the ModelContext into the environment
    }
}

