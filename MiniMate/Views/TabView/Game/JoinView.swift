//
//  JoinView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/19/25.
//

import SwiftUI

struct JoinView: View {
    @Binding var userModel: UserModel?
    @StateObject var authModel: AuthModel
    @Binding var showHost: Bool

    @State private var gameStarted = false
    @State private var gameModel: GameModel = GameModel(id: "", lat: nil, long: nil, date: Date(), completed: false, numberOfHoles: 18)
    @State private var gameCode: String = ""
    @State private var isConnected: Bool = false

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
                    .foregroundColor(.primary)
                    .padding(.leading, 30)
                Spacer()
            }

            Form {
                gameInfoSection
                if gameModel.id != "" {
                    playersSection
                    Button{
                        authModel.fetchGameData(gameCode: gameCode) { model in
                            if let model = model {
                                if let index = model.playerIDs.firstIndex(of: userModel!.mini) {
                                    model.playerIDs.remove(at: index)
                                }
                                self.gameModel = model
                                authModel.addAndUpdateGame(game: model) { success in
                                    print(success ? "Updated Game" : "Could not update Game")
                                }
                                self.gameModel = GameModel(id: "", lat: nil, long: nil, date: Date(), completed: false, numberOfHoles: 18)
                                isConnected = false
                            } else {
                                print("Game not found")
                            }
                        }

                    } label: {
                        Text("Exit Game")
                    }
                    
                } else {
                    Button{
                        authModel.fetchGameData(gameCode: gameCode) { model in
                            if let model = model {
                                model.playerIDs.append(userModel!.mini)
                                self.gameModel = model
                                authModel.addAndUpdateGame(game: model) { success in
                                    print(success ? "Updated Game" : "Could not update Game")
                                    isConnected = true
                                }
                            } else {
                                print("Game not found")
                            }
                        }

                    } label: {
                        Text("Join Game")
                    }
                }
            }
        }
        .onAppear(){
            
        }
    }

    // MARK: - View Sections

    private var gameInfoSection: some View {
        Section(header: Text("Game Info")) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Enter Code:")
                    Spacer()
                    if !isConnected {
                        TextField("Code:", text: $gameCode)
                    } else {
                        Text("Code: \(gameModel.id)")
                    }
                }

                if gameModel.id != "" {
                    Divider()

                    HStack {
                        Text("Date:")
                        Spacer()
                        Text(gameModel.date.formatted(date: .abbreviated, time: .shortened))
                    }

                    HStack {
                        Text("Number of Holes:")
                        Spacer()
                        Text("\(gameModel.numberOfHoles)")
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }


    private var playersSection: some View {
        Section("Players: \(gameModel.playerIDs.count)") {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(gameModel.playerIDs) { player in
                        PlayerIconView(player: player, isRemovable: false) {
                        }
                    }

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
