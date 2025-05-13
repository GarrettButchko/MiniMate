import SwiftUI
import MapKit
import FirebaseAuth
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var context
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewManager = ViewManager()
    @StateObject private var authModel: AuthViewModel
    @StateObject private var gameModel: GameViewModel

    let locFuncs = LocFuncs()

    @State private var selectedTab = 1
    @State private var previousView: ViewType?
    
    init() {
        // 1) create your AuthViewModel first
        let auth = AuthViewModel()
        _authModel = StateObject(wrappedValue: auth)

        // 2) create an initial Game (or fetch one from your context)
        let initialGame =  Game(id: "", date: Date(), completed: false, numberOfHoles: 18, started: false, dismissed: false, live: false, lastUpdated: Date(), holes: [], players: [])

        // 3) now inject both into your GameViewModel
        _gameModel = StateObject(
          wrappedValue: GameViewModel(
            game: initialGame,
            authModel: auth,
            onlineGame: true
          )
        )
      }

    var body: some View {
        ZStack {
            Group {
                switch viewManager.currentView {
                case .main(let tab):
                    MainTabView(viewManager: viewManager, authModel: authModel, gameModel: gameModel, selectedTab: tab)
                    
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
                    
                case .scoreCard:
                   ScoreCardView(viewManager: viewManager, authModel: authModel, gameModel: gameModel)
                    
                
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
        .onAppear {
              // Only for debugging! Remove this in production.
              //gameModel.clearAllGames(in: context)
              //print("🗑️ Cleared all games at launch")
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
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    @ObservedObject var gameModel: GameViewModel
    @StateObject var locationHandler = LocationHandler()
    
    @State var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            StatsView(viewManager: viewManager, authModel: authModel)
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                .tag(0)

            MainView(viewManager: viewManager, authModel: authModel, locationHandler: locationHandler, gameModel: gameModel)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(1)
            if authModel.userModel?.id != "IDGuest" {
                CourseView(viewManager: viewManager, authModel: authModel, locationHandler: locationHandler, gameModel: gameModel)
                    .tabItem { Label("Courses", systemImage: "figure.golf") }
                    .tag(2)
            }
        }
        .onAppear {
            authModel.loadOrCreateUserIfNeeded(user: authModel.firebaseUser, in: context) {
                try? context.save()
                if NetworkChecker.shared.isConnected {
                    authModel.saveUserModel(authModel.userModel!) { _ in }
                }
            }
        }
    }
}
