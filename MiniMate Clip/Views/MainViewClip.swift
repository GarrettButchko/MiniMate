import SwiftUI

struct MainViewClip: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) var context
    
    let course: Course?
    
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
                    if let logo = course?.logo{
                        Divider()
                            .frame(height: 30)
                        Image(logo)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                    }
                    
                    Spacer()
                    Button {
                        nameIsPresented = true
                    } label: {
                        Image("logoOpp")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                    }
                }
                
                // MARK: - Game Action Buttons
                
                ZStack{
                    if authModel.userModel != nil{
                        VStack{
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 175)
                            ScrollView{
                                
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 125)
                                
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
                                
                                if let courseLink = course?.link{
                                    Button {
                                        if let url = URL(string: courseLink) {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        HStack{
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Visit for more info!")
                                                    .foregroundStyle(.mainOpp)
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                
                                                Text("Tap here to visit the \(course?.name ?? "company") website!")
                                                    .foregroundStyle(.mainOpp)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .multilineTextAlignment(.leading)
                                                    .padding(.trailing)
                                            }
                                            Spacer()
                                            if let courselogo = course?.logo{
                                                Image(courselogo)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 60)
                                            }
                                            Spacer()
                                        }
                                        .padding()
                                    }
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 25))
                                    .padding(.bottom)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                    
                    VStack(){
                        if let course = course {
                            TitleView(colors: course.colors)
                                .frame(height: 150)
                        } else {
                            TitleView()
                                .frame(height: 150)
                        }
                        
                        
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
                                        HostViewClip(course: course, showHost: $showHost, authModel: authModel, viewManager: viewManager, gameModel: gameModel)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                if authModel.userModel?.name == "Guest"{
                    nameIsPresented = true
                }
            }
        }
        .alert("Add your name?", isPresented: $nameIsPresented) {
            TextField("Name", text: $userName)
                .onChange(of: userName) { _, newValue in
                    if newValue.count > 18 {
                        userName = String(newValue.prefix(18))
                    }
                }
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
