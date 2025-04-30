// JoinView.swift
// MiniMate
//
// Refactored to use SwiftData models and AuthViewModel

import SwiftUI

struct JoinView: View {
    @Environment(\.modelContext) private var context
    @State private var game: Game = Game(id: "", lat: nil, long: nil, date: Date())

    @StateObject var authModel: AuthViewModel
    
    @StateObject var viewManager: ViewManager

    @State private var gameCode: String = ""
    
    @State private var message: String = ""
    
    @Binding var showHost: Bool
    @State private var showExitAlert: Bool = false

    var body: some View {
        VStack {
            Capsule()
                .frame(width: 38, height: 6)
                .foregroundColor(.gray)
                .padding(10)

            HStack {
                Text("Join Game")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 30)
                Spacer()
            }
            .padding(.bottom, 10)

            Form {
                gameInfoSection

                if !game.id.isEmpty {
                    playersSection

                    Section {
                        Button("Exit Game") {
                            showExitAlert = true
                        }
                        .foregroundColor(.red)
                        .alert("Exit Game?", isPresented: $showExitAlert) {
                            Button("Leave", role: .destructive) {
                                exitGame()
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                    .onAppear {
                        authModel.listenForGameUpdates(id: game.id) { updated in
                            if let updated = updated {
                                game = updated
                                if updated.started {
                                    authModel.stopListeningForGameUpdates(id: game.id)
                                    showHost = false
                                    viewManager.navigateToScoreCard($game, true)
                                }
                            }
                        }
                    }
                } else {
                    Section {
                        Button("Join Game") {
                            joinGame()
                        }
                        .disabled(gameCode.isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var gameInfoSection: some View {
        Section(header: Text("Game Info")) {
            if game.id.isEmpty {
                HStack {
                    Text("Enter Code:")
                    Spacer()
                    TextField("Game Code", text: $gameCode)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                    if message != "" {
                        Text("Error: " + message)
                    }
                    
                }
            } else {
                HStack {
                    Text("Code:")
                    Spacer()
                    Text(game.id)
                }
                HStack {
                    Text("Date:")
                    Spacer()
                    Text(game.date.formatted(date: .abbreviated, time: .shortened))
                }
                HStack {
                    Text("Holes:")
                    Spacer()
                    Text("\(game.numberOfHoles)")
                }
            }
        }
    }

    private var playersSection: some View {
        Section(header: Text("Players: \(game.players.count)")) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(game.players) { player in
                        PlayerIconView(player: player, isRemovable: false) {}
                    }
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Waiting...").font(.caption)
                    }
                    .padding(.horizontal)
                }
            }
            .frame(height: 75)
        }
    }

    // MARK: - Actions

    private func joinGame() {
        authModel.fetchGame(id: gameCode) { fetched in
            guard let fetched = fetched, let user = authModel.userModel else { return }
            if !fetched.started && fetched.players.contains(where: { $0.id == user.id }) == false{
                game = fetched
                let newPlayer = Player(id: user.id, name: user.name, photoURL: user.photoURL, totalStrokes: 0, inGame: true)
                initializeHoles(for: newPlayer)
                game.players.append(newPlayer)
                authModel.addOrUpdateGame(game) { _ in }
            } else if fetched.started {
                message = "Game has already started."
            } else if fetched.players.contains(where: { $0.id == user.id }) {
                message = "You are already in this game."
            }
        }
    }

    private func exitGame() {
        guard let user = authModel.userModel else { return }
        game.players.removeAll { $0.id == user.id }
        authModel.addOrUpdateGame(game) { _ in }
        game = Game(id: "", lat: nil, long: nil, date: Date())
    }

    // MARK: - Helpers

    private func initializeHoles(for player: Player) {
        player.holes = (0..<game.numberOfHoles).map { idx in
            let hole = Hole(number: idx + 1, par: 2)
            hole.player = player
            return hole
        }
    }
}
