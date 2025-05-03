// ScoreCardView.swift
// MiniMate
//
// Refactored to use SwiftData models and AuthViewModel

import SwiftUI

struct ScoreCardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthViewModel
    @ObservedObject var gameModel: GameViewModel
    
    @State private var scrollOffset: CGFloat = 0
    @State private var uuid: UUID? = nil
    
    @State var showInfoView: Bool = false
    
    @State private var hasUploaded = false   // renamed for clarity
    
    var body: some View {
        VStack {
            headerView
            scoreGridView
            footerView
        }
        .padding()
        .sheet(isPresented: $showInfoView) {
            GameInfoView(game: gameModel.bindingForGame(), isSheetPresent: $showInfoView)
        }
        .onChange(of: gameModel.gameValue.completed) { old, new in
            guard new, !hasUploaded else { return }
                hasUploaded = true
                  // 1️⃣ Persist
                  gameModel.finishAndPersistGame(in: context)
            
                // 2️⃣ Then navigate back
                  viewManager.navigateToMain(1)
        }
    }
    
    // MARK: Header
    private var headerView: some View {
        HStack {
            Text("Scorecard")
                .font(.title).fontWeight(.bold)
            Spacer()
            Button {
                showInfoView = true
            } label: {
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.vertical)
    }
    
    /// Player Row
    private var playerHeaderRow: some View {
        HStack {
            Text("Name")
                .frame(width: 100, height: 60)
                .font(.title3).fontWeight(.semibold)
            Divider()
            SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                HStack {
                    ForEach(gameModel.gameValue.players) { player in
                        if player.id != gameModel.gameValue.players[0].id { Divider() }
                        PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: 30, background: .ultraThinMaterial)
                            .frame(width: 100, height: 60)
                    }
                }
            }
        }
        .frame(height: 60)
        .padding(.top)
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
                        authModel: authModel, online: gameModel.onlineGame
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
                Text("Hole \(i)")
                    .font(.body).fontWeight(.medium)
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
            SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                HStack {
                    ForEach(gameModel.gameValue.players) { player in
                        if player.id != gameModel.gameValue.players[0].id { Divider() }
                        Text("Total: \(player.holes.reduce(0) { $0 + $1.strokes })")
                            .frame(width: 100, height: 60)
                            .onChange(of: player.holes.reduce(0) { $0 + $1.strokes }) { oldValue, newValue in
                                player.totalStrokes = newValue
                            }
                    }
                }
            }
        }
        .frame(height: 60)
        .padding(.bottom)
    }
    
    // MARK: Footer complete game button and timer
    private var footerView: some View {
        HStack {
            Button {
                // 1️⃣ Prevent double-taps
                        guard !hasUploaded else { return }
                        hasUploaded = true

                        // 2️⃣ Deep-clone & save *this* game (exactly once)
                        gameModel.finishAndPersistGame(in: context)
                
                        // 3️⃣ Navigate back
                        viewManager.navigateToMain(1)
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
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - PlayerScoreColumnView

struct PlayerScoreColumnView: View {
    @Binding var player: Player
    @Binding var game: Game
    @StateObject var authModel: AuthViewModel
    var onlineGame: Bool
    
    var body: some View {
        VStack {
            ForEach($player.holes.sorted(by: {$0.number.wrappedValue < $1.number.wrappedValue}), id: \.id) { $hole in
                HoleRowView(hole: $hole)
                  .onChange(of: hole.strokes) { new, old in
                    if onlineGame {
                      game.lastUpdated = Date()
                      authModel.addOrUpdateGame(game) { _ in }
                    }
                  }
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
    @StateObject var authModel: AuthViewModel
    let online: Bool
    
    var body: some View {
        HStack {
            ForEach($players, id: \.id) { $player in
                
                    if player.id != game.players[0].id{
                        Divider()
                    }
                    PlayerScoreColumnView(
                        player: $player,
                        game: $game,
                        authModel: authModel,
                        onlineGame: online
                    )
                    .frame(width: 100)
                
            }
        }
    }
}
