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
    @Binding var game: Game
    
    @State private var scrollOffset: CGFloat = 0
    @State private var uuid: UUID? = nil
    @State var onlineGame: Bool
    
    @State var showInfoView: Bool = false
    
    @State private var elapsedTime: Int = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            headerView
            scoreGridView
            footerView
        }
        .onAppear(perform: setupView)
        .onReceive(timer) { _ in elapsedTime += 1 }
        .onDisappear(perform: cleanupView)
        .padding()
        .sheet(isPresented: $showInfoView) {
            GameInfoView(game: $game, isSheetPresent: $showInfoView)
        }
        .onChange(of: game.dismissed) { old, new in
            if new {
                dismissAndSave()
            }
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
                    ForEach(game.players) { player in
                        if player.id != game.players[0].id { Divider() }
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
                        players: $game.players,
                        game: $game,
                        authModel: authModel,
                        online: onlineGame
                    )
                }
            }
        }
    }
    
    /// first column with holes and number i.e "hole 1"
    private var holeNumbersColumn: some View {
        VStack {
            ForEach(1...game.numberOfHoles, id: \.self) { i in
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
                    ForEach(game.players) { player in
                        if player.id != game.players[0].id { Divider() }
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
            Spacer()
            Button(action: completeGame) {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.blue)
                        .frame(width: 200, height: 60)
                    Text("Complete Game")
                        .foregroundColor(.white).fontWeight(.bold)
                }
            }
            Spacer()
            Text(timeString(from: elapsedTime))
                .frame(minWidth: 50)
            Spacer()
        }
    }
    
    // MARK: Lifecycle
    private func setupView() {
        /// inserts game into swiftdata
        /// context.insert(game)
        
        if game.modelContext == nil {
                context.insert(game)
            }

            // 2️⃣ Insert each Player and their Holes
            for player in game.players {
                // skip invalid players
                guard !player.id.isEmpty, !player.name.isEmpty else { continue }

                if player.modelContext == nil {
                    context.insert(player)
                }
                for hole in player.holes {
                    if hole.modelContext == nil {
                        context.insert(hole)
                    }
                }
            }

            // 3️⃣ (Optional) Save immediately so you’ll see no more validation errors
            do {
                try context.save()
            } catch {
                print("SwiftData save error:", error)
            }
        
        
        
        elapsedTime = 0
        if onlineGame {
            authModel.saveUserModel(authModel.userModel!) { _ in }
            authModel.listenForGameUpdates(id: game.id) { updated in
                if let updated = updated {
                    if updated.completed {
                        viewManager.navigateToMain(1)
                    }
                    // _Don’t_ replace the binding. Instead, merge field by field:
                    game.date         = updated.date
                    game.completed    = updated.completed
                    game.numberOfHoles = updated.numberOfHoles
                    game.started      = updated.started
                    game.dismissed    = updated.dismissed
                    game.totalTime    = updated.totalTime
                    
                    // Sync your SwiftData holes array in-place:
                    for (i, holeDTO) in updated.holes.enumerated() {
                        guard i < game.holes.count else { break }
                        game.holes[i].strokes = holeDTO.strokes
                    }
                    
                    // Sync your players & their holes in-place:
                    for (i, playerDTO) in updated.players.enumerated() {
                        guard i < game.players.count else { continue }
                        let local = game.players[i]
                        local.totalStrokes = playerDTO.totalStrokes
                        local.inGame       = playerDTO.inGame
                        
                        for (h, holeDTO) in playerDTO.holes.enumerated() {
                            guard h < local.holes.count else { break }
                            local.holes[h].strokes = holeDTO.strokes
                        }
                    }
                } else {
                    dismissAndSave()
                }
            }
        }
    }
    
    private func cleanupView() {
        /// adds timer time at the end to game data
        game.totalTime = elapsedTime
        /// cancels timer
        timer.upstream.connect().cancel()
    }
    
    private func completeGame() {
        print("Running")
        game.completed = true
        game.lastUpdated = Date()

        if onlineGame {
            authModel.addOrUpdateGame(game) { _ in }
        }

        // Check if the game already exists in the user model's games array
        
            if !authModel.userModel!.games.contains(where: { $0.id == game.id }) {
                authModel.userModel!.games.append(game)
            }
        
        for player in game.players {
            print("Player ID: \(player.id), Name: \(player.name)")
        }
            do {
                try context.save()
                print("✅ SwiftData Save Successful")
            } catch {
                print("❌ SwiftData Save Error:", error)
            }  // <- Ensure local persistence before any Firebase call

            if onlineGame {
                authModel.saveUserModel(authModel.userModel!) { _ in
                    finishAndNavigate()
                }
            } else {
                finishAndNavigate()
            }
        print("Done running")
        
    }

    private func finishAndNavigate() {
        // This ensures navigation happens *after* local + cloud saves
        dismissAndSave()
    }


    
    private func dismissAndSave() {
        game.dismissed = true
        game.live = false
        if let player = game.players.first(where: { $0.id == authModel.userModel?.id }) {
            player.inGame = false
        }
        if !game.completed {
            if let idx = authModel.userModel?.games.firstIndex(where: { $0.id == game.id }) {
                authModel.userModel?.games.remove(at: idx)
            }
            if onlineGame {
                authModel.deleteGame(id: game.id) { _ in }
            }
            context.delete(game)
        } else if onlineGame {
            game.lastUpdated = Date()
            authModel.addOrUpdateGame(game) { _ in }
        }
        if onlineGame {
            authModel.saveUserModel(authModel.userModel!) { _ in }
            authModel.stopListeningForGameUpdates(id: game.id)
        }
        viewManager.navigateToMain(1)
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
            ForEach(player.holes.sorted(by: { $0.number < $1.number }), id: \.number) { hole in
                if let index = player.holes.firstIndex(where: { $0.id == hole.id }) {
                    HoleRowView(hole: $player.holes[index])
                        .onChange(of: player.holes[index].strokes) { _, _ in
                            if onlineGame {
                                game.lastUpdated = Date()
                                authModel.addOrUpdateGame(game) { _ in }
                            }
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
