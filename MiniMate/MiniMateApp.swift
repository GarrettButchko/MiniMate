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

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
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
                // ➌ A verified transaction has completed
            case .verified(let transaction):
                // – mark it finished so StoreKit can clear it
                await transaction.finish()
                // – optionally trigger your thank-you UI:
                NotificationCenter.default.post(
                    name: .didCompleteDonation,
                    object: transaction.productID
                )
                
                // ➍ If it failed verification, you can log or ignore
            case .unverified(_, let error):
                print("⚠️ Unverified transaction:", error.localizedDescription)
            }
        }
    }
}

@main
struct YourApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    
    init(){
        //LocFuncs().clearSwiftDataStore()
        _ = PurchaseManager.shared 
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UserModel.self, Player.self, Game.self, Hole.self])
    }
    
    
}

