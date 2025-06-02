import SwiftUI
import StoreKit
import MapKit

struct MainView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    @ObservedObject var locationHandler: LocationHandler
    @ObservedObject var gameModel: GameViewModel

    @State private var userName = "Guest"
    @State private var nameIsPresented = false
    @State private var isSheetPresented = false
    @State var showLoginOverlay = false
    @State var isOnlineMode = false
    @State var showHost = false
    @State var showJoin = false
    @State var showFirstStage: Bool = false
    @State var showGuestAdd: Bool = false
    @State var showenGuestAdd: Bool = false
    @State var alreadyShown: Bool = false
    
    @State var editOn: Bool = false
    
    @State var showDonation: Bool = false
    
    var body: some View {
        let storeManager = StoreManager(authModel: authModel)
        
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
                                Image("logoOpp")
                                    .resizable()
                                    .scaledToFill()
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image("logoOpp")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
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
                    if let user = authModel.userModel{
                        let analyzer = UserStatsAnalyzer(user: user)
                        
                        VStack{
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 175)
                            
                            ScrollView{
                                VStack{
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 115)
                                    
                                    VStack{
                                        BannerAdView(adUnitID: "ca-app-pub-8261962597301587/6344452429") // Replace with real one later
                                            .frame(height: 50)
                                            .padding()
                                    }
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                    .padding(.bottom, 10)
                                        
                                        
                                    
                                    if analyzer.hasGames{
                                        Button {
                                            viewManager.navigateToGameReview(user.games.sorted(by: { $0.date > $1.date }).first!)
                                        } label: {
                                            SectionStatsView(title: "Last Game") {
                                                HStack{
                                                    HStack{
                                                        VStack(alignment: .leading, spacing: 8) {
                                                            Text("Winner")
                                                                .font(.caption)
                                                                .foregroundStyle(.secondary)
                                                                .foregroundStyle(.mainOpp)
                                                            PhotoIconView(photoURL: analyzer.winnerOfLatestGame?.photoURL, name: (analyzer.winnerOfLatestGame?.name ?? "N/A") + "🥇", imageSize: 30, background: Color.yellow)
                                                            Spacer()
                                                        }
                                                        Spacer()
                                                    }
                                                    .padding()
                                                    .frame(height: 120)
                                                    .background(colorScheme == .light
                                                                ? AnyShapeStyle(Color.white)
                                                                : AnyShapeStyle(.ultraThinMaterial))
                                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                                    StatCard(title: "Your Strokes", value: "\(analyzer.usersScoreOfLatestGame)", color: .green)
                                                }
                                                
                                                BarChartView(data: analyzer.usersHolesOfLatestGame, title: "Recap of Game")
                                                
                                            }
                                        }
                                    } else {
                                        Image("logoOpp")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                        Spacer()
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
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
                                            gameModel.createGame(online: true, startingLoc: nil)
                                            showHost = true
                                        }
                                        .sheet(isPresented: $showHost) {
                                            
                                            HostView(showHost: $showHost, authModel: authModel, viewManager: viewManager, locationHandler: locationHandler, gameModel: gameModel)
                                                .presentationDetents([.large])
                                        }

                                        gameModeButton(title: "Join", icon: "person.2.fill", color: .orange) {
                                            gameModel.resetGame()
                                            showJoin = true
                                        }
                                        .sheet(isPresented: $showJoin) {
                                            JoinView(authModel: authModel, viewManager: viewManager, gameModel: gameModel, showHost: $showJoin)
                                                .presentationDetents([.large])
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                                } else {
                                    HStack(spacing: 16) {
                                        gameModeButton(title: "Quick", icon: "person.fill", color: .blue) {
                                            gameModel.createGame(online: false, startingLoc: nil)
                                            showHost = true
                                            withAnimation {
                                                isOnlineMode = false
                                            }
                                        }
                                        .sheet(isPresented: $showHost) {
                                            HostView(showHost: $showHost, authModel: authModel, viewManager: viewManager, locationHandler: locationHandler, gameModel: gameModel)
                                                .presentationDetents([.large])
                                        }
                                        if authModel.userModel?.id == "IDGuest" {
                                            HStack {
                                                Image(systemName: "globe")
                                                Text("Connect")
                                                    .fontWeight(.semibold)
                                            }
                                            .padding(10)
                                            .frame(maxWidth: .infinity, minHeight: 50)
                                            .background(RoundedRectangle(cornerRadius: 15).fill().foregroundStyle(.secondary))
                                            .foregroundColor(.mainOpp)
                                        } else {
                                            gameModeButton(title: "Connect", icon: "globe", color: .green) {
                                                withAnimation {
                                                    isOnlineMode = true
                                                }
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
                        
                        // Donation Button
                        HStack {
                            Spacer()
                            Button {
                                if !showFirstStage {
                                    withAnimation {
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
                                HStack {
                                    if showFirstStage {
                                        Text("Tap to buy Pro!")
                                            .transition(.move(edge: .trailing).combined(with: .opacity))
                                            .foregroundStyle(.white)
                                    }
                                    Text("✨")
                                }
                                .padding()
                                .frame(height: 50)
                                .background(Color.yellow)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .shadow(radius: 10)
                            }
                            .sheet(isPresented: $showDonation) {
                                ProView {
                                    Task {
                                        if let product = storeManager.products.first {
                                            await storeManager.purchasePro(product)
                                        } else {
                                            print("No products loaded")
                                        }
                                    }
                                }
                            }
                            .padding()
                        }

                    }
                }
                
            }
            .padding([.top, .horizontal])
            .onAppear(){
                if authModel.userModel?.games.count == 0 && LocFuncs().fetchUser(by: "IDGuest", context: context) != nil && authModel.userModel?.id != "IDGuest" && LocFuncs().fetchUser(by: "IDGuest", context: context)?.games.count != 0 {
                    
                    print(authModel.userModel?.id ?? "No ID")
                    withAnimation{
                        showGuestAdd = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if authModel.userModel?.id == "IDGuest" && showenGuestAdd == false{
                        nameIsPresented = true
                        showenGuestAdd = true
                    }
                }
            }
            .alert("Add your name?", isPresented: $nameIsPresented) {
                TextField("Name", text: $userName)
                Button("Add") { authModel.userModel?.name = userName}
                Button("Cancel", role: .cancel) {}
            }
            
            if showGuestAdd && alreadyShown == false{
                ZStack{
                    Rectangle()
                        .background(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    if let guestUser = LocFuncs().fetchUser(by: "IDGuest", context: context){
                        VStack{
                            Text("We found games added by a guest user!")
                                .font(.headline)
                                .foregroundStyle(.mainOpp)
                                .padding(.top)
                            Text("Would you like to add these games to your account?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            ScrollView{
                                ForEach(guestUser.games, id: \.self){ game in
                                    GameGridView(editOn: $editOn, authModel: authModel, game: game)
                                }
                            }
                            .padding()
                            
                            HStack{
                                gameModeButton(title: "Add Games", color: .green) {
                                    alreadyShown = true
                                    withAnimation{
                                        showGuestAdd = false
                                    }
                                    authModel.userModel?.games.append(contentsOf: guestUser.games)
                                    authModel.saveUserModel(authModel.userModel!){ _ in }
                                    context.delete(guestUser)
                                }
                                gameModeButton(title: "Cancel", color: .blue) {
                                    alreadyShown = true
                                    withAnimation{
                                        showGuestAdd = false
                                    }
                                }
                            }
                            .padding()
                        }
                        .background(RoundedRectangle(cornerRadius: 25).fill().foregroundStyle(.ultraThinMaterial))
                        .padding(.horizontal, 20)
                        .frame(height: 400)
                    }
                }
                
            }
        }
        .ignoresSafeArea(.keyboard)
        
    }

    func gameModeButton(title: String, icon: String? = nil, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
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



