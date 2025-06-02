//
//  StatsView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//

import SwiftUI
import Charts

struct StatsView: View {
    
    @Environment(\.modelContext) private var context
    
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthViewModel
    
    var pickerSections = ["Games", "Overview"]
    
    @State var pickedSection = "Games"
    @State var searchText: String = ""
    
    @State var latest = true
    @State var editOn = false
    
    var body: some View {
        if let userModel = authModel.userModel {
            let analyzer = UserStatsAnalyzer(user: userModel)
            VStack{
                HStack {
                    ZStack {
                        if pickedSection == "Games" {
                            Text("Game Stats")
                                .font(.title).fontWeight(.bold)
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            Text("Overview")
                                .font(.title).fontWeight(.bold)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .animation(.easeInOut(duration: 0.35), value: pickedSection)
                    
                    Spacer()
                    
                    ZStack{
                        if pickedSection == "Games" {
                            Button {
                                withAnimation{
                                    editOn.toggle()
                                }
                            } label: {
                                if editOn {
                                    Text("Done")
                                        .transition(.opacity)
                                } else {
                                    Text("Edit")
                                        .transition(.opacity)
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: pickedSection)
                }
                
                Picker("Section", selection: $pickedSection) {
                    ForEach(pickerSections, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.segmented)
                
                
                ZStack {
                    if pickedSection == "Games" {
                        gamesSection
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        
                        if analyzer.hasGames {
                            overViewSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                                .onAppear {
                                    editOn = false
                                }
                        } else {
                            ScrollView{
                                Image("logoOpp")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .padding()
                            }
                            .onAppear {
                                editOn = false
                            }
                        }
                            
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: pickedSection)
            }
            .padding([.top, .horizontal])
        }
    }
    
    var games: [Game] {
        
        var gameTemp: [Game] = authModel.userModel!.games
        
        if !searchText.isEmpty {
            gameTemp = gameTemp.filter { $0.date.formatted(date: .abbreviated, time: .shortened).lowercased().contains(searchText.lowercased()) }
        }
        if latest {
            gameTemp = gameTemp.sorted(by: {$0.date > $1.date})
        }
        return gameTemp
    }
    
    private var gamesSection: some View {
        ZStack{
            ScrollView{
                    let analyzer = UserStatsAnalyzer(user: authModel.userModel!)
                    
                    Rectangle()
                        .frame(height: 60)
                        .foregroundStyle(Color.clear)
                    if analyzer.hasGames {
                        ForEach(games, id: \.id) { game in
                            Button {
                                viewManager.navigateToGameReview(game)
                            } label: {
                                GameGridView(editOn: $editOn, authModel: authModel, game: game)
                                    .padding(.vertical)
                                    .transition(.opacity)
                            }
                        }
                    } else {
                        Image("logoOpp")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding()
                    }
                
                
            }
            VStack{
                HStack{
                    ZStack {
                        // Background with light fill
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial) // Light background
                            .frame(height: 50)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search", text: $searchText)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding(.trailing, 5)
                        }
                        .padding()
                    }
                    .padding(.vertical)
                    
                    Button {
                        withAnimation(){
                            latest.toggle()
                        }
                    } label: {
                        
                        ZStack{
                            
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 50, height: 50)
                            
                            if latest{
                                Image(systemName: "arrow.up")
                                    .transition(.scale)
                                    .frame(width: 60, height: 60)
                            } else {
                                Image(systemName: "arrow.down")
                                    .transition(.scale)
                                    .frame(width: 60, height: 60)
                            }
                        }
                        
                        
                        
                    }
                    
                }
                Spacer()
            }
        }
    }
    
    private var overViewSection: some View {
        ScrollView {
                let analyzer = UserStatsAnalyzer(user: authModel.userModel!)
                
                SectionStatsView(title: "Basic Stats") {
                    HStack{
                        StatCard(title: "Games Played", value: "\(analyzer.totalGamesPlayed)", color: .blue)
                        StatCard(title: "Players Faced", value: "\(analyzer.totalPlayersFaced)", color: .green)
                        StatCard(title: "Holes Played", value: "\(analyzer.totalHolesPlayed)", color: .blue)
                    }
                    
                    HStack{
                        StatCard(title: "Average Strokes per Game", value: String(format: "%.1f", analyzer.averageStrokesPerGame), color: .blue)
                        StatCard(title: "Average Strokes per Hole", value: String(format: "%.1f", analyzer.averageStrokesPerHole), color: .green)
                    }
                }
                .padding(.top)
                
                SectionStatsView(title: "Average 18 Hole Game"){
                    BarChartView(data: analyzer.averageHoles18, title: "Average Strokes")
                }
                .padding(.top)
                
                
                SectionStatsView(title: "Misc Stats") {
                    HStack{
                        StatCard(title: "Best Game", value: "\(analyzer.bestGameStrokes ?? 0)", color: .blue)
                        StatCard(title: "Worst Game", value: "\(analyzer.worstGameStrokes ?? 0)", color: .green)
                        StatCard(title: "Hole in One's", value: "\(analyzer.holeInOneCount)", color: .blue)
                    }
                }
                .padding(.top)
                
                SectionStatsView(title: "Average 9 Hole Game"){
                    BarChartView(data: analyzer.averageHoles9, title: "Average Strokes")
                }
                .padding(.top)
                
            }
    }

}




struct GameGridView: View {
    @Binding var editOn: Bool
    @StateObject var authModel: AuthViewModel
    @Environment(\.modelContext) private var context
    var game: Game
    var sortedPlayers: [Player] {
        game.players.sorted(by: { $0.totalStrokes < $1.totalStrokes })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) { // Adds vertical spacing
            // Game Info & Players Row
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(game.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(.mainOpp)
                    
                    Text("Number of Holes: \(game.numberOfHoles)")
                        .font(.caption).foregroundColor(.secondary)
                }
                
                    
                    if game.players.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) { // Player icon spacing
                                ForEach(game.players) { player in
                                    if game.players.count != 0{
                                        if player.id != game.players[0].id {
                                            Divider()
                                                .frame(height: 50)
                                        }
                                    }
                                    
                                        if sortedPlayers[0] == player {
                                            PhotoIconView(photoURL: player.photoURL, name: player.name + "🥇", imageSize: 20, background: Color.yellow)
                                        } else {
                                            PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: 20, background: .ultraThinMaterial)
                                        }
                                    
                                }
                            }
                        }
                        .frame(height: 50)
                    } else {
                        PhotoIconView(photoURL: game.players[0].photoURL, name: game.players[0].name, imageSize: 20, background: .ultraThinMaterial)
                    }
                
            }
            
            // Bar Chart
            BarChartView(data: averageStrokes(), title: "Average Strokes")
            
            if editOn {
                HStack{
                    
                    ShareLink(item: makeShareableSummary(for: game)) {
                      Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                    }
                    .padding()
                    
                    Button {
                        if let index = authModel.userModel?.games.firstIndex(where: { $0.id == game.id }) {
                            withAnimation {
                                
                                _ = authModel.userModel?.games.remove(at: index)
                            }
                            authModel.saveUserModel(authModel.userModel!) { _ in }
                        }
                        context.delete(game)
                    } label: {
                        ZStack{
                            Rectangle().fill(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                
                            Text("Delete Game")
                                .foregroundStyle(.white)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .frame(height: 32)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    
    /// Build a plain-text summary (you could also return a URL to a generated PDF/image)
    func makeShareableSummary(for game: Game) -> String {
      var lines = ["MiniMate Scorecard",
                   "Date: \(game.date.formatted(.dateTime))",
                   ""]
      
      for player in game.players {
          var holeLine = ""
          
          for hole in player.holes {
                holeLine += "|\(hole.strokes)"
          }
          
          lines.append("\(player.name): \(player.totalStrokes) strokes (\(player.totalStrokes))")
          lines.append("Holes " + holeLine)
          
      }
      lines.append("")
      lines.append("Download MiniMate: https://apps.apple.com/app/id6745438125")
      return lines.joined(separator: "\n")
    }
    
    /// Returns one Hole per hole-number, whose `strokes` is the integer average
    /// across all players for that hole.
    func averageStrokes() -> [Hole] {
        let holeCount   = game.numberOfHoles
        let playerCount = game.players.count
        guard playerCount > 0 else { return [] }

        // 1) Sum strokes per hole index (0-based)
        var sums = [Int](repeating: 0, count: holeCount)
        for player in game.players {
            for hole in player.holes {
                let idx = hole.number - 1
                sums[idx] += hole.strokes
            }
        }

        // 2) Build averaged Hole objects
        return sums.enumerated().map { (idx, total) in
            let avg = total / playerCount
            return Hole(number: idx + 1, par: 2, strokes: avg)
        }
    }
}



