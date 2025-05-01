import SwiftUI
import MapKit

struct MainView: View {
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthViewModel
    @StateObject var locationHandler: LocationHandler

    @State private var isSheetPresented = false
    @State var showLoginOverlay = false
    @State var isOnlineMode = false
    @State var showHost = false
    @State var showJoin = false
    @State var showFirstStage: Bool = false
    
    @State var showDonation: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // MARK: - Top Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome back,")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(authModel.userModel?.name ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Button(action: {
                        isSheetPresented = true
                    }) {
                        if let photoURL = authModel.firebaseUser?.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        }
                    }
                    .sheet(isPresented: $isSheetPresented) {
                        ProfileView(
                            viewManager: viewManager,
                            authModel: authModel,
                            isSheetPresent: $isSheetPresented,
                            showLoginOverlay: $showLoginOverlay
                        )
                        
                    }
                }

                

                // MARK: - Game Action Buttons
                
                ZStack{
                    if authModel.firebaseUser != nil{
                        let analyzer = UserStatsAnalyzer(user: authModel.userModel!)
                        
                        ScrollView{
                            VStack{
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 310)
                                    
                                if analyzer.hasGames{
                                    SectionStatsView(title: "Last Game") {
                                        HStack{
                                            
                                            HStack{
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("Winner")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                    PhotoIconView(photoURL: analyzer.winnerOfLatestGame?.photoURL, name: analyzer.winnerOfLatestGame?.name ?? "N/A", imageSize: 30, background: .ultraThinMaterial)
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                            .padding()
                                            .frame(height: 120)
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 25))
                                            StatCard(title: "Your Strokes", value: "\(analyzer.usersScoreOfLatestGame)", color: .green)
                                        }
                                        
                                        BarChartView(data: analyzer.usersHolesOfLatestGame, title: "Recap of Game")
                                        
                                    }
                                } else {
                                    Image("logoOpp")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    VStack(){
                        
                        TitleView()
                            .frame(height: 150)
                        
                        VStack {
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
                                            HostView(showHost: $showHost, authModel: authModel, viewManager: viewManager, locationHandler: locationHandler, onlineGame: isOnlineMode)
                                                .presentationDetents([.large])
                                        }

                                        gameModeButton(title: "Join", icon: "person.2.fill", color: .orange) {
                                            showJoin = true
                                        }
                                        .sheet(isPresented: $showJoin) {
                                            JoinView(authModel: authModel, viewManager: viewManager, showHost: $showJoin)
                                                .presentationDetents([.large])
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                                } else {
                                    HStack(spacing: 16) {
                                        gameModeButton(title: "Offline", icon: "person.fill", color: .blue) {
                                            showHost = true
                                            withAnimation {
                                                isOnlineMode = false
                                            }
                                        }
                                        .sheet(isPresented: $showHost) {
                                            HostView(showHost: $showHost, authModel: authModel, viewManager: viewManager, locationHandler: locationHandler, onlineGame: false)
                                                .presentationDetents([.large])
                                        }

                                        gameModeButton(title: "Online", icon: "globe", color: .green) {
                                            withAnimation {
                                                isOnlineMode = true
                                            }
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: isOnlineMode)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        
                        Spacer()
                        
                        HStack(){
                            Spacer()
                            Button{
                                if !showFirstStage {
                                    withAnimation(){
                                        showFirstStage = true
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                                        if showFirstStage {
                                            withAnimation {
                                                showFirstStage = false
                                            }
                                        }
                                    }
                                } else {
                                    showDonation = true
                                }
                                
                            } label: {
                                HStack{
                                    if showFirstStage {
                                        Text("Tap to buy me a Soda!")
                                            .transition(.move(edge: .trailing).combined(with: .opacity))
                                            .foregroundStyle(.white)
                                    }
                                    Text("🥤")
                                }
                                .padding()
                                .frame(height: 50)
                                .background(Color.indigo)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                            }
                            .sheet(isPresented: $showDonation) {
                                DonationView()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .ignoresSafeArea(.keyboard)
    }

    func gameModeButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(RoundedRectangle(cornerRadius: 15).fill().foregroundStyle(color))
            .foregroundColor(.white)
        }
    }
}



