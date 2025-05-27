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

    @State private var course: Course?
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            Group{
                ContentViewClip(course: course)
            }.onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                if let incomingURL = userActivity.webpageURL {
                    let resolvedCourse = resolveCourse(from: incomingURL.absoluteString)
                    course = resolvedCourse
                }
            }
        }
        .modelContainer(sharedContainer)
        
    }

    /// This function doesn't mutate `self`, just returns a Course
    func resolveCourse(from url: String) -> Course? {
        switch url {
            case "https://circuit-leaf.com/mini-mate/S":
                return Course(
                    id: "S",
                    name: "Sweeties Candy Company",
                    logo: "sweeties",
                    colors: [Color.red, Color.green, Color.yellow],
                    link: "https://www.sweetiescandy.com/",
                    pars: [2, 3, 5, 3, 2, 3, 4, 3, 2, 2, 3, 4, 3, 4, 2, 3, 2, 5, 7]
                )
            default:
                return nil
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        MobileAds.shared.start(completionHandler: nil)
        return true
    }
}
