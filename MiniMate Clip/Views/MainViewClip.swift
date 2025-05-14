import SwiftUI

struct MainViewClip: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) var context
    
    @ObservedObject var viewManager: ViewManagerClip
    @ObservedObject var authModel: AuthViewModelClip
    @ObservedObject var gameModel: GameViewModelClip

    @State private var isSheetPresented = false
    @State private var nameIsPresented = false
    @State private var userName = "Guest"
    @State var showHost = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // MARK: - Top Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome,")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(authModel.userModel?.name ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Spacer()
                    
                    Image("logoOpp")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)

                }

                // MARK: - Game Action Buttons
                
                ZStack{
                    if let user = authModel.userModel{
                        let analyzer = UserStatsAnalyzer(user: user)
                        
                        ScrollView{
                        
                            VStack{
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 300)
                                
                                Button {
                                    if let url = URL(string: "https://apps.apple.com/app/id6745438125") {
                                            UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack{
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Download Full App Now!")
                                                .foregroundStyle(.mainOpp)
                                                .font(.headline)
                                                .fontWeight(.semibold)

                                            Text("Tap here to download the full MiniMate app to unlock your complete game history, track progress over time, and enjoy a personalized mini golf experience — all synced to your account!")
                                                .foregroundStyle(.mainOpp)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .multilineTextAlignment(.leading)
                                                .padding(.trailing)
                                        }
                                        Spacer()
                                        Image("Icon")
                                            .resizable()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        Spacer()
                                    }
                                    .padding()
                                }
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .padding(.bottom)
                                    
                                if analyzer.hasGames{
                                    
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
                    
                    VStack(){
                        
                        TitleView()
                            .frame(height: 150)
                        
                        VStack {
                            HStack {
                                
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 30, height: 30)
                                 
                                Spacer()

                                Text("Start a Game")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .transition(.opacity.combined(with: .scale))
                                    
                                    
                                Spacer()

                                // Mirror the left spacer for symmetry
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 30, height: 30)
                            }

                            ZStack {
                                
                                    HStack(spacing: 16) {
                                        gameModeButton(title: "Quick", icon: "person.fill", color: .blue) {
                                            gameModel.createGame(online: false, startingLoc: nil)
                                            showHost = true
                                        }
                                        .sheet(isPresented: $showHost) {
                                            HostViewClip(showHost: $showHost, authModel: authModel, viewManager: viewManager, gameModel: gameModel)
                                                .presentationDetents([.large])
                                        }
                                    }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            if authModel.userModel?.name == "Guest"{
                nameIsPresented = true
            }
        }
        .alert("Add your name?", isPresented: $nameIsPresented) {
            TextField("Name", text: $userName)
            Button("Add") { authModel.userModel?.name = userName}
            Button("Cancel", role: .cancel) {}
        }
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



