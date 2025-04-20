import SwiftUI
import FirebaseAuth
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var context
    @Environment(\.scenePhase) private var scenePhase

    @StateObject var viewManager = ViewManager()
    @StateObject var authModel = AuthModel()

    let locFuncs = LocFuncs()

    @State private var selectedTab = 1
    @State private var userModel: UserModel?
    @State private var previousView: ViewManager.ViewType?

    var body: some View {
        ZStack {
            Group {
                switch viewManager.currentView {
                case .main:
                    mainTabView
                        
                case .login:
                    LoginView(
                        viewManager: viewManager,
                        authModel: authModel,
                        userModel: $userModel
                    )
                case .signup:
                    SignUpView(
                        viewManager: viewManager,
                        authModel: authModel,
                        userModel: $userModel
                    )
                case .welcome:
                    WelcomeView(viewManager: viewManager)
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

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            StatsView(viewManager: viewManager, authModel: authModel, userModel: $userModel)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
                .tag(0)

            MainView(
                viewManager: viewManager,
                authModel: authModel,
                userModel: $userModel
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(1)

            CourseView(viewManager: viewManager)
                .tabItem {
                    Label("Courses", systemImage: "figure.golf")
                }
                .tag(2)
        }
        .onAppear {
            //locFuncs.deletePersistentStore()
            
            if NetworkChecker.shared.isConnected {
                authModel.saveUserData(user: userModel!) { _ in }
            }
            loadOrCreateUserIfNeeded()
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

    func loadOrCreateUserIfNeeded() {
        guard let firebaseUser = Auth.auth().currentUser else {
            print("⚠️ No Firebase user.")
            return
        }

        // Try to load from SwiftData
        if let localUser = locFuncs.fetchUser(by: firebaseUser.uid, context: context) {
            print("✅ Loaded local user: \(localUser.mini.name)")
            userModel = localUser
        } else {
            print("⚠️ No local user found. Trying Firebase...")

            // Try from Firebase DB
            authModel.fetchUserData { model in
                if let model = model {
                    context.insert(model)
                    try? context.save()
                    print("✅ Loaded from Firebase and saved locally: \(model.mini.name)")
                    userModel = model
                } else {
                    // Create new user if none in Firebase
                    let newUser = UserModel(
                        id: firebaseUser.uid, mini: UserModelEssentials(
                            id: firebaseUser.uid,
                            name: firebaseUser.displayName ?? "New User",
                            photoURL: firebaseUser.photoURL
                        ),
                        email: firebaseUser.email,
                        games: []
                    )
                    context.insert(newUser)
                    try? context.save()
                    authModel.saveUserData(user: newUser) { _ in }
                    print("🆕 Created and saved new user.")
                    userModel = newUser
                }
            }
        }
    }


}
