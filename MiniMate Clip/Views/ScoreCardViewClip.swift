// ScoreCardView.swift
// MiniMate
//
// Refactored to use SwiftData models and AuthViewModel

import SwiftUI
import Combine

struct ScoreCardViewClip: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    
    let course: Course?
    
    @StateObject var viewManager: ViewManagerClip
    @StateObject var authModel: AuthViewModelClip
    @ObservedObject var gameModel: GameViewModelClip
    
    @State private var scrollOffset: CGFloat = 0
    @State private var uuid: UUID? = nil
    
    @State var showRecap: Bool = false
    
    @State private var hasUploaded = false   // renamed for clarity
    
    var body: some View {
        ZStack{
            VStack {
                headerView
                scoreGridView
                footerView
            }
            .padding()
            .onChange(of: gameModel.gameValue.completed) { old, new in
                endGame()
                withAnimation {
                    showRecap = true
                }
            }
            if showRecap {
                RecapView(userModel: authModel.userModel!, viewManager: viewManager)
                    .transition(.opacity)
            }
            
        }
    }
    
    // MARK: Header
    private var headerView: some View {
        HStack {
            Text("Scorecard")
                .font(.title).fontWeight(.bold)
            if let logo = course?.logo{
                Divider()
                    .frame(height: 30)
                Image(logo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
            }
            Spacer()
        }
    }
    
    // MARK: Score Grid
    private var scoreGridView: some View {
        VStack {
            playerHeaderRow
            Divider()
            scoreRows
            Divider()
            totalRow
        }
        .background(
            course?.colors.first.map { AnyShapeStyle($0.opacity(0.2))} ?? AnyShapeStyle(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.vertical)
    }
    
    /// Player Row
    private var playerHeaderRow: some View {
        // If there’s no host yet, render nothing (or a placeholder)
        guard let firstPlayer = gameModel.gameValue.players.first else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            HStack {
                Text("Name")
                    .frame(width: 100, height: 60)
                    .font(.title3).fontWeight(.semibold)
                Divider()
                SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                    HStack {
                        ForEach(gameModel.gameValue.players) { player in
                            // now this is safe — firstPlayer is non-nil
                            if player.id != firstPlayer.id {
                                Divider()
                            }
                            PhotoIconView(photoURL: player.photoURL,
                                          name: player.name,
                                          imageSize: 30, background: .ultraThinMaterial)
                            .frame(width: 100, height: 60)
                        }
                    }
                }
            }
                .frame(height: 60)
                .padding(.top)
        )
    }
    
    
    /// Score columns and hole icons
    private var scoreRows: some View {
        ScrollView {
            HStack(alignment: .top) {
                holeNumbersColumn
                Divider()
                SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                    PlayerColumnsView(
                        players: gameModel.binding(for: \.players),
                        game: gameModel.bindingForGame(),
                        authModel: authModel, gameModel: gameModel
                    )
                }
            }
        }
    }
    
    /// first column with holes and number i.e "hole 1"
    private var holeNumbersColumn: some View {
        VStack {
            ForEach(1...gameModel.gameValue.numberOfHoles, id: \.self) { i in
                if i != 1 { Divider() }
                VStack{
                    Text("Hole \(i)")
                        .font(.body).fontWeight(.medium)
                    if let course = course, course.hasPars {
                        Text("Par: \(course.pars[i - 1])")
                            .font(.caption)
                    }
                }
                .frame(height: 60)
            }
        }
        .frame(width: 100)
    }
    
    /// totals row
    private var totalRow: some View {
        HStack {
            Text("Total")
                .frame(width: 100, height: 60)
                .font(.title3).fontWeight(.semibold)
            Divider()
            SyncedScrollViewRepresentable(
                scrollOffset:   $scrollOffset,
                syncSourceID:   $uuid
            ) {
                HStack {
                    ForEach(gameModel.gameValue.players) { player in
                        if player.id != gameModel.gameValue.players.first?.id {
                            Divider()
                        }
                        Text("Total: \(player.totalStrokes)")
                            .frame(width: 100, height: 60)
                    }
                }
            }
        }
        .frame(height: 60)
        .padding(.bottom)
    }
    
    
    // MARK: Footer complete game button and timer
    private var footerView: some View {
        VStack{
            HStack {
                Button {
                    gameModel.setCompletedGame(true)
                    endGame()
                    withAnimation {
                        showRecap = true
                    }
                }  label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.blue)
                            .frame(width: 200, height: 60)
                        Text("Complete Game")
                            .foregroundColor(.white).fontWeight(.bold)
                    }
                }
                
                
            }
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    private func endGame() {
        guard !hasUploaded else { return }
        hasUploaded = true
        // 1️⃣ finish-and-persist before we pop the view
        gameModel.finishAndPersistGame(in: context)
        // 2️⃣ now it’s safe to navigate
        
    }
}

// MARK: - PlayerScoreColumnView

struct PlayerScoreColumnView: View {
    @Binding var player: Player
    @ObservedObject var gameModel: GameViewModelClip
    @StateObject var authModel: AuthViewModelClip
    
    var body: some View {
        VStack {
            ForEach($player.holes.sorted(by: {$0.number.wrappedValue < $1.number.wrappedValue}), id: \.id) { $hole in
                HoleRowView(hole: $hole)
            }
        }
    }
}

// MARK: - HoleRowView

struct HoleRowView: View {
    @Binding var hole: Hole
    
    var body: some View {
        VStack {
            if hole.number != 1 { Divider() }
            NumberPickerView(selectedNumber: $hole.strokes, minNumber: 0, maxNumber: 10)
                .frame(height: 60)
        }
    }
}
struct PlayerColumnsView: View {
    @Binding var players: [Player]
    @Binding var game: Game
    @StateObject var authModel: AuthViewModelClip
    @StateObject var gameModel: GameViewModelClip
    
    var body: some View {
        HStack {
            ForEach($players, id: \.id) { $player in
                
                if player.id != game.players[0].id{
                    Divider()
                }
                PlayerScoreColumnView(
                    player: $player,
                    gameModel: gameModel,
                    authModel: authModel
                )
                .frame(width: 100)
            }
        }
    }
}
