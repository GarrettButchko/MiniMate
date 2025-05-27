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

final class PurchaseManager {
    static let shared = PurchaseManager()

    private init() {
        Task {
            await listenForTransactions()
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            switch result {
            case .verified(let transaction):
                await transaction.finish()
                NotificationCenter.default.post(
                    name: .didCompleteDonation,
                    object: transaction.productID
                )
            case .unverified(_, let error):
                print("⚠️ Unverified transaction:", error.localizedDescription)
            }
        }
    }
}

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    private var sharedContainer: ModelContainer = {
        let appGroupID = "group.com.circuit-leaf.mini-mate"
        let sharedURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
            .appendingPathComponent("SharedSwiftData")

        let config = ModelConfiguration(url: sharedURL)
        return try! ModelContainer(
            for: UserModel.self, Player.self, Game.self, Hole.self,
            configurations: config
        )
    }()

    init() {
        // Initialize purchase system
        _ = PurchaseManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedContainer)
    }
}
