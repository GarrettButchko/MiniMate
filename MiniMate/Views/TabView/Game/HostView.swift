//
//  GameView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/18/25.
//

import SwiftUI

struct HostView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @Binding var userModel: UserModel?
    @StateObject var authModel: AuthModel
    @Binding var showHost: Bool

    @State private var gameStarted = false
    @State private var gameModel: GameModel = GameModel(id: "", lat: nil, long: nil, date: Date(), completed: false, numberOfHoles: 18)
    @State private var showAddPlayerAlert = false
    @State private var showDeleteAlert = false
    @State private var newPlayerName: String = ""
    @State private var playerToDelete: UserModelEssentials?

    var body: some View {
        VStack {
            Capsule()
                .frame(width: 38, height: 6)
                .foregroundColor(.gray)
                .padding(10)

            HStack {
                Text("Hosting Game")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
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
            setupGame()
            startPollingForPlayers()
        }
        .onChange(of: showHost) { oldValue, newValue in
            handleHostDismissal(newValue)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                showHost = false
            }
        }
        .alert("Add another player?", isPresented: $showAddPlayerAlert) {
            TextField("Name", text: $newPlayerName)
            Button("Add Player") {
                addNewPlayer()
            }.disabled(newPlayerName.isEmpty)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please type the name")
        }
        .alert("Delete this Player?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let player = playerToDelete {
                    removePlayer(player)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - View Sections

    private var gameInfoSection: some View {
        Section(header: Text("Game Info")) {
            HStack {
                Text("Game Code:")
                Spacer()
                Text(gameModel.id)
            }
            
            DatePicker("Date", selection: $gameModel.date, displayedComponents: [.date, .hourAndMinute])
                .onChange(of: gameModel.date) { _, _ in
                    authModel.addAndUpdateGame(game: gameModel) { _ in }
                }

            HStack {
                Text("Number of Holes:")
                NumberPickerView(selectedNumber: $gameModel.numberOfHoles, maxNumber: 20)
                    .onChange(of: gameModel.numberOfHoles) { _, _ in
                        authModel.addAndUpdateGame(game: gameModel) { _ in }
                    }
            }
        }
    }

    private var playersSection: some View {
        Section("Players: \(gameModel.playerIDs.count)") {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(gameModel.playerIDs) { player in
                        PlayerIconView(player: player, isRemovable: player.id.count == 6) {
                            playerToDelete = player
                            showDeleteAlert = true
                        }
                    }

                    addPlayerButton

                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .frame(width: 40, height: 40)
                        Text("Searching...")
                            .font(.caption)
                    }
                    .padding(.horizontal)
                }
            }
            .frame(height: 75)
        }
    }

    private var startGameSection: some View {
        Section {
            Button("Start Game") {
                gameStarted = true
                showHost = false
            }
        }
    }

    private var addPlayerButton: some View {
        Button {
            newPlayerName = ""
            showAddPlayerAlert = true
        } label: {
            VStack {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    Image(systemName: "plus")
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.primary)
                }
                Text("Add Local Player")
                    .font(.caption)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Logic

    private func setupGame() {
        gameModel.id = generateGameCode()
        if let host = userModel?.mini {
            gameModel.playerIDs.append(host)
            authModel.addAndUpdateGame(game: gameModel) { _ in }
        }
    }

    private func addNewPlayer() {
        let newPlayer = UserModelEssentials(id: generateGameCode(), name: newPlayerName)
        gameModel.playerIDs.append(newPlayer)
        authModel.addAndUpdateGame(game: gameModel) { _ in }
    }

    private func removePlayer(_ player: UserModelEssentials) {
        gameModel.playerIDs.removeAll { $0.id == player.id }
        authModel.addAndUpdateGame(game: gameModel) { _ in }
    }

    private func handleHostDismissal(_ isShowing: Bool) {
        if !isShowing {
            if gameStarted {
                userModel?.games.append(gameModel)
            } else {
                authModel.deleteGameData(gameCode: gameModel.id) { _ in }
            }
        }
    }

    private func generateGameCode(length: Int = 6) -> String {
        let characters = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
    
    private func startPollingForPlayers() {
        guard showHost else { return }  // Don't start if sheet is not showing

        authModel.fetchGameData(gameCode: gameModel.id) { model in
            if let model = model {
                self.gameModel.playerIDs = model.playerIDs
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                startPollingForPlayers()
            }
        }
    }

}

// MARK: - Player Icon View

struct PlayerIconView: View {
    let player: UserModelEssentials
    var isRemovable: Bool
    var onTap: (() -> Void)?

    var body: some View {
        Group {
            if isRemovable {
                Button {
                    onTap?()
                } label: {
                    PhotoIconView(photoURL: player.photoURL, name: player.name)
                }
            } else {
                PhotoIconView(photoURL: player.photoURL, name: player.name)
            }
        }
        .padding(.horizontal)
    }
}
