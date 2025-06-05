import SwiftUI
import SwiftData
import MapKit
import GoogleMobileAds

@main
struct MiniMate_ClipApp: App {
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

    var body: some Scene {
        WindowGroup {
            Group {
                if let course = launchCoordinator.course {
                    ContentViewClip(course: course)
                } else {
                    ProgressView("Loading...")
                }
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                if let incomingURL = userActivity.webpageURL {
                    let resolved = CourseResolver.resolve(url: incomingURL.absoluteString)
                    withAnimation(){
                        launchCoordinator.course = resolved
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
