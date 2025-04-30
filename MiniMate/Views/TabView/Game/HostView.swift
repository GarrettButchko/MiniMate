// HostView.swift
// MiniMate
//
// Refactored to use new SwiftData models and AuthViewModel

import SwiftUI

struct HostView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @State private var game: Game = Game(id: "", lat: nil, long: nil, date: Date())
    var onlineGame: Bool
    @Binding var showHost: Bool

    @StateObject var authModel: AuthViewModel
    @StateObject var viewManager: ViewManager

    @State private var showAddPlayerAlert = false
    @State private var showDeleteAlert = false
    @State private var newPlayerName = ""
    @State private var playerToDelete: String?
    
    // how long (in seconds) a game stays live without activity
    private let ttl: TimeInterval = 20 * 60
    // when this game was last pushed to Firebase
    @State private var lastUpdated: Date = Date()
    // a one-second ticker
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State  private var timeRemaining: TimeInterval = 20 * 60

    var body: some View {
        VStack {
            Capsule()
                .frame(width: 38, height: 6)
                .foregroundColor(.gray)
                .padding(10)

            HStack {
                Text(onlineGame ? "Hosting Game" : "Game Setup")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 30)
                Spacer()
            }

            Form {
                gameInfoSection
                playersSection
                startGameSection
            }
        }
        .onAppear {
            if !game.started {
                setupGame()
                if onlineGame {
                    authModel.listenForGameUpdates(id: game.id) { updatedGame in
                        if let updatedGame = updatedGame {
                            game = updatedGame
                        } else {
                            showHost = false
                        }
                    }
                }
            }
        }
        .onChange(of: showHost) { _, newValue in
            handleHostDismissal(newValue)
        }
        .alert("Add Local Player?", isPresented: $showAddPlayerAlert) {
            TextField("Name", text: $newPlayerName)
            Button("Add") { addNewPlayer() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Player?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let player = playerToDelete {
                    removePlayer(player)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onReceive(ticker) { _ in
          // compute seconds until (lastUpdated + ttl)
          let expireDate = lastUpdated.addingTimeInterval(ttl)
          timeRemaining = max(0, expireDate.timeIntervalSinceNow)
          
          // if we’ve actually hit zero, you could auto-dismiss:
          if timeRemaining <= 0 {
            showHost = false
          }
        }
    }

    // MARK: - Sections

    private var gameInfoSection: some View {
        Section(header: Text("Game Info")) {
            if onlineGame {
                HStack {
                    Text("Game Code:")
                    Spacer()
                    Text(game.id)
                }
                HStack {
                    Text("Expires in:")
                    Spacer()
                    // format MM:SS
                    Text(timeString(from: Int(timeRemaining)))
                      .monospacedDigit()
                  }
            }

            DatePicker("Date & Time", selection: $game.date)
                .onChange(of: game.date) { _, _ in pushUpdate() }

            HStack {
                Text("Holes:")
                NumberPickerView(selectedNumber: $game.numberOfHoles, minNumber: 9, maxNumber: 21)
                    .onChange(of: game.numberOfHoles) { _, _ in
                        updateHoles()
                        pushUpdate()
                    }
            }
        }
    }

    private var playersSection: some View {
        Section(header: Text("Players: \(game.players.count)")) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(game.players) { player in
                        PlayerIconView(player: player, isRemovable: player.id.count != 6) {
                            playerToDelete = player.id
                            showDeleteAlert = true
                        }
                    }
                    Button(action: { newPlayerName = ""; showAddPlayerAlert = true }) {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "plus")
                            }
                            Text("Add Player").font(.caption)
                        }
                        .padding(.horizontal)
                    }
                    if onlineGame {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(width: 40, height: 40)
                            Text("Searching...").font(.caption)
                        }.padding(.horizontal)
                    }
                }
            }
            .frame(height: 75)
        }
    }

    private var startGameSection: some View {
        Section {
            Button("Start Game") {
                // mark started
                game.started = true
                
                // **only now** create/update in Firebase**
                if onlineGame {
                    authModel.addOrUpdateGame(game) { _ in }
                }
                
                // dismiss and navigate
                showHost = false
                if game.players.count > 1 {
                    viewManager.navigateToScoreCard($game, onlineGame)
                } else {
                    authModel.deleteGame(id: game.id) { _ in }
                    viewManager.navigateToScoreCard($game, false)
                }
            }
        }
    }


    // MARK: - Logic
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func setupGame() {
        game.id = generateGameCode()
        game.numberOfHoles = 18
        if let user = authModel.userModel {
            guard !user.id.isEmpty, !user.name.isEmpty else {
                print("⚠️ Invalid host user, not inserting")
                return
            }
            
            let host = Player(
                id: user.id,
                name: user.name,
                photoURL: user.photoURL,
                totalStrokes: 0,
                inGame: true
            )
        
            game.players.append(host)
            updateHoles()
        }
        if onlineGame && !game.live { pushUpdate() }
        game.live = true
    }



    private func addNewPlayer() {
        let newPlayer = Player(
            id: generateGameCode(),
            name: newPlayerName,
            photoURL: nil,
            totalStrokes: 0,
            inGame: true
        )
        print("Host Player - id: \(newPlayer.id), name: \(newPlayer.name)")
        game.players.append(newPlayer)
        updateHoles()
        if onlineGame { pushUpdate() }
    }


    private func removePlayer(_ id: String) {
        game.players.removeAll { $0.id == id }
        if onlineGame { pushUpdate() }
    }

    private func handleHostDismissal(_ isShowing: Bool) {
        authModel.stopListeningForGameUpdates(id: game.id)
        
        if !isShowing {
            if onlineGame {
                authModel.deleteGame(id: game.id) { _ in }
                game.live = false
            }
        }
    }


    private func updateHoles() {
        for player in game.players {
            player.holes = (0..<game.numberOfHoles).map { index in
                let hole = Hole(number: index + 1, par: 2)
                hole.player = player
                return hole
            }
        }
    }

    private func initializeHoles(for player: Player) {
        player.holes = (0..<game.numberOfHoles).map { index in
            let hole = Hole(number: index + 1, par: 2)
            hole.player = player
            return hole
        }
    }

    private func pushUpdate() {
      guard onlineGame else { return }
      game.lastUpdated = Date()          // save into your model too
      lastUpdated       = Date()         // restart our local clock
      authModel.addOrUpdateGame(game) { _ in }
    }


    private func generateGameCode(length: Int = 6) -> String {
        let chars = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
}


// MARK: - Player Icon View

struct PlayerIconView: View {
    let player: Player
    var isRemovable: Bool
    var onTap: (() -> Void)?
    var imageSize: CGFloat = 30

    var body: some View {
        Group {
            if isRemovable {
                Button {
                    onTap?()
                } label: {
                    PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: imageSize, background: .ultraThinMaterial)
                }
            } else {
                PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: imageSize, background: .ultraThinMaterial)
            }
        }
        .padding(.horizontal)
    }
}
