import SwiftUI

struct MainView: View {
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthModel

    @State private var isSheetPresented = false
    @State var showLoginOverlay = false
    @State var isOnlineMode = false
    @State var showHost = false
    @State var showJoin = false

    @Binding var userModel: UserModel?

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // MARK: - Top Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome back,")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(userModel?.mini.name ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Button(action: {
                        isSheetPresented = true
                    }) {
                        AsyncImage(url: authModel.user?.photoURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                            default:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                    }
                    .sheet(isPresented: $isSheetPresented) {
                        ProfileView(
                            viewManager: viewManager,
                            authModel: authModel,
                            isSheetPresent: $isSheetPresented,
                            userModel: $userModel,
                            showLoginOverlay: $showLoginOverlay
                        )
                    }
                }

                TitleView()
                    .frame(height: 200)

                // MARK: - Game Action Buttons
                GroupBox {
                    HStack {
                        ZStack {
                            if isOnlineMode {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        isOnlineMode = false
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(.primary)
                                            .frame(width: 30, height: 30)
                                        Image(systemName: "chevron.left")
                                            .foregroundStyle(.ultraThickMaterial)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                            } else {
                                // Keep layout aligned using an invisible spacer
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 30, height: 30)
                            }
                        }

                        Spacer()

                        ZStack {
                            if isOnlineMode {
                                Text("Online Options")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .transition(.opacity.combined(with: .scale))
                            } else {
                                Text("Start a Game")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .animation(.easeInOut(duration: 0.35), value: isOnlineMode)

                        Spacer()

                        // Mirror the left spacer for symmetry
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 30, height: 30)
                    }



                    

                    ZStack {
                        if isOnlineMode {
                            HStack(spacing: 16) {
                                gameModeButton(title: "Host", icon: "antenna.radiowaves.left.and.right", color: .purple) {
                                    showHost = true
                                }
                                .sheet(isPresented: $showHost) {
                                    HostView(userModel: $userModel, authModel: authModel, showHost: $showHost)
                                }

                                gameModeButton(title: "Join", icon: "person.2.fill", color: .orange) {
                                    showJoin = true
                                }
                                .sheet(isPresented: $showJoin) {
                                    JoinView(userModel: $userModel, authModel: authModel, showHost: $showJoin)
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        } else {
                            HStack(spacing: 16) {
                                gameModeButton(title: "Offline", icon: "person.fill", color: .blue) {
                                    // Handle offline
                                }

                                gameModeButton(title: "Online", icon: "globe", color: .green) {
                                    withAnimation {
                                        isOnlineMode = true
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: isOnlineMode)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(radius: 3)

                HStack(spacing: 16) {
                    StatCard(title: "Games Played", value: "2", color: .blue)
                    StatCard(title: "Wins", value: "1", color: .green)
                }
                .padding(.top)

                Spacer(minLength: 50)
            }
            .padding()
        }
    }

    func gameModeButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Capsule().foregroundStyle(color))
            .foregroundColor(.white)
            .shadow(radius: 4)
        }
    }
}

struct StatCard: View {
    var title: String
    var value: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Spacer()
        }
        .padding()
        .frame(height: 120)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(radius: 3)
    }
}
