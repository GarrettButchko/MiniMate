import SwiftUI
import MapKit
import FirebaseAuth
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var context
    @Environment(\.scenePhase) private var scenePhase

    @StateObject var viewManager = ViewManager()
    @StateObject var authModel = AuthViewModel()

    let locFuncs = LocFuncs()

    @State private var selectedTab = 1
    @State private var previousView: ViewType?

    var body: some View {
        ZStack {
            Group {
                switch viewManager.currentView {
                case .main(let tab):
                    MainTabView(viewManager: viewManager, authModel: authModel, selectedTab: tab)
                    
                case .login:
                    LoginView(
                        viewManager: viewManager,
                        authModel: authModel
                    )
                case .signup:
                    SignUpView(
                        viewManager: viewManager,
                        authModel: authModel
                    )
                case .welcome:
                    WelcomeView(viewManager: viewManager)
                    
                case .scoreCard(let gameModel, let onlineGame):
                    ScoreCardView(viewManager: viewManager, authModel: authModel, game: gameModel, onlineGame: onlineGame)

                
                case .gameReview(let gameModel):
                    GameReviewView(viewManager: viewManager, game: gameModel)
                }
                
            }
            .transition(currentTransition)
            
        }
        .animation(.easeInOut(duration: 0.4), value: viewManager.currentView)
        .onChange(of: viewManager.currentView, { oldValue, newValue in
            previousView = viewManager.currentView
        })
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("App is active")
                try? context.save()
            case .inactive:
                print("App is inactive")
                try? context.save()
            case .background:
                print("App moved to background")
                try? context.save()
            @unknown default:
                break
            }
        }
        
    }

    // MARK: - Custom transition based on view switch
    private var currentTransition: AnyTransition {
        switch (previousView, viewManager.currentView) {
        case (.login, .signup):
            return .move(edge: .trailing)
        case (.signup, .login):
            return .move(edge: .leading)
        case (_, .main):
            return .opacity.combined(with: .scale)
        case (_, .welcome):
            return .opacity
        default:
            return .opacity
        }
    }
}

struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthViewModel
    @StateObject var locationHandler = LocationHandler()
    
    @State var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            StatsView(viewManager: viewManager, authModel: authModel)
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(0)

            MainView(viewManager: viewManager, authModel: authModel, locationHandler: locationHandler)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(1)

            CourseView(viewManager: viewManager, authModel: authModel, locationHandler: locationHandler)
                .tabItem { Label("Courses", systemImage: "figure.golf") }
                .tag(2)
        }
        .onAppear {
            if NetworkChecker.shared.isConnected {
                authModel.saveUserModel(authModel.userModel!) { _ in }
            }
            authModel.loadOrCreateUserIfNeeded(context)
            try? context.save()
        }
    }
}
