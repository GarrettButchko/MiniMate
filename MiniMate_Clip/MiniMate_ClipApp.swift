import SwiftUI
import SwiftData
import MapKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct MiniMate_ClipApp: App {
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

    @StateObject private var launchCoordinator = LaunchCoordinator()
    @StateObject private var authModel = AuthViewModelClip()

    var body: some Scene {
        WindowGroup {
            Group {
                if let course = launchCoordinator.course {
                    ContentViewClip(auth: authModel, course: course)
                } else {
                    ContentViewClip(auth: authModel, course: nil)
                }
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                if let incomingURL = userActivity.webpageURL {
                    AdminCodeResolver.resolve(url: incomingURL.absoluteString, authModel: authModel){ course in
                        let resolved = course
                        withAnimation(){
                            launchCoordinator.course = resolved
                        }
                    }
                }
            }
        }
        .modelContainer(sharedContainer)
    }
}

class LaunchCoordinator: ObservableObject {
    @Published var course: Course?
}
