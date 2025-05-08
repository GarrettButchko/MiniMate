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
    
    @State var pickedSection = "Overview"
    @State var searchText: String = ""
    
    @State var latest = true
    @State var editOn = false
    
    var body: some View {
        if authModel.firebaseUser != nil, let userModel = authModel.userModel {
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
                        } else {
                            ScrollView{
                                Image("logoOpp")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .padding()
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: pickedSection)
            }
            .padding()
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
                if authModel.firebaseUser != nil {
                    
                    
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
                                .keyboardType(.emailAddress)
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
            if authModel.firebaseUser != nil {
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

}

struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    var title: String
    var value: String
    var color: Color

    var body: some View {
        HStack{
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
            Spacer()
        }
        .padding()
        .frame(height: 120)
        .background(colorScheme == .light
                    ? AnyShapeStyle(Color.white)
                    : AnyShapeStyle(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}


struct SectionStatsView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(.mainOpp)
                Spacer()
            }
            content()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}


struct GameGridView: View {
    @Binding var editOn: Bool
    @StateObject var authModel: AuthViewModel
    @Environment(\.modelContext) private var context
    var game: Game

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
                
                if authModel.firebaseUser != nil {
                    let userStats = UserStatsAnalyzer(user: authModel.userModel!)
                    
                    if game.players.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) { // Player icon spacing
                                ForEach(game.players) { player in
                                    if player.id != game.players[0].id {
                                        Divider()
                                            .frame(height: 50)
                                    }
                                    if userStats.winnerOfLatestGame == player {
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
            }
            
            // Bar Chart
            BarChartView(data: averageStrokes(), title: "Average Strokes")
            
            if editOn {
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
                            .clipShape(.buttonBorder)
                            .frame(height: 32)
                        Text("Delete Game")
                            .foregroundStyle(.white)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
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


struct BarChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    let data: [Hole]
    let title: String

    var body: some View {
        Chart {
            ForEach(data, id: \.self) { dataPoint in
                BarMark(
                    x: .value("Hole", dataPoint.number),
                    y: .value("Strokes", dataPoint.strokes)
                )
                .annotation(position: .top) { // Adds stroke count above bar
                    Text("\(dataPoint.strokes)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: [.blue, .green]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .stride(by: 3)) { value in
                AxisValueLabel {
                    if let hole = value.as(Int.self) {
                        Text("H\(hole)") // Shows "H1", "H2", etc.
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 5))
        }
        .chartXAxisLabel(position: .bottom, alignment: .center) {
          Text(title)
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .chartXScale(domain: data.isEmpty ? 0...1 : 1...data.count)
        .chartYScale(domain: 0...(data.map { $0.strokes }.max() ?? 10) + 1)
        .frame(height: 75)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(colorScheme == .light
                                                            ? AnyShapeStyle(Color.white)
                                                            : AnyShapeStyle(.ultraThinMaterial)))
    }
}

