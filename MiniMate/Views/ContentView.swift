import SwiftUI
import FirebaseAuth
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context

    @StateObject var viewManager = ViewManager()
    @StateObject var authModel = AuthModel()

    let locFuncs = LocFuncs()

    @State private var selectedTab = 1
    @State private var user: UserModel?
    @State private var isConnected = false
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
                        userModel: $user
                    )
                case .signup:
                    SignUpView(
                        viewManager: viewManager,
                        authModel: authModel,
                        userModel: $user
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
        .onAppear {
            isConnected = NetworkChecker.shared.isConnected
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            StatsView(viewManager: viewManager)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
                .tag(0)

            MainView(
                viewManager: viewManager,
                authModel: authModel,
                userModel: $user
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
            if isConnected {
                authModel.saveUserData(user: user!) { _ in }
            }
            if authModel.user != nil {
                loadLocalUser()
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

    private func loadLocalUser() {
        if let firebaseUser = authModel.user{
            if let localUser = locFuncs.fetchUser(by: firebaseUser.uid, context: context) {
                user = localUser
                print("✅ Local user loaded: \(localUser.name)")
            } else {
                print("⚠️ No local user found for \(firebaseUser.uid).")
            }
        } else {
            print("⚠️ No Firebase user found. Will retry shortly...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadLocalUser() // retry after 0.5 seconds
            }
            return
        }
    }
}
