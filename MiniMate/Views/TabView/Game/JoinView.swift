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
            .onChange(of: showHost) { oldValue, newValue in
                if gameModel.id != "" {
                    authModel.fetchGameData(gameCode: gameCode) { model in
                        if let model = model {
                            // Remove this player from the game
                            if let index = model.playerIDs.firstIndex(of: userModel!.mini) {
                                model.playerIDs.remove(at: index)
                            }
                            
                            // Save the updated model
                            authModel.addAndUpdateGame(game: model) { success in
                                if success {
                                    print("✅ Player removed and game updated")
                                    self.gameModel = GameModel(id: "", lat: nil, long: nil, date: Date(), completed: false, numberOfHoles: 18, playerIDs: [])
                                    
                                } else {
                                    print("❌ Could not update game")
                                }
                            }
                        } else {
                            print("❌ Game not found")
                        }
                    }
                }
            }

            Form {
                gameInfoSection
                if gameModel.id != "" {
                    playersSection
                    Button {
                        authModel.fetchGameData(gameCode: gameModel.id) { model in
                            if let model = model {
                                // Remove this player from the game
                                
                                let modelCopy = model
                                
                                if let index = model.playerIDs.firstIndex(where: { $0.id == userModel!.mini.id }) {
                                    model.playerIDs.remove(at: index)
                                }

                                // Save the updated model
                                authModel.addAndUpdateGame(game: modelCopy) { success in
                                    if success {
                                        print("✅ Player removed and game updated")
                                        self.gameModel = GameModel(id: "", lat: nil, long: nil, date: Date(), completed: false, numberOfHoles: 18, playerIDs: [])
                                        
                                    } else {
                                        print("❌ Could not update game")
                                    }
                                }
                            } else {
                                print("❌ Game not found")
                            }
                        }
                    } label: {
                        Text("Exit Game")
                    }
                    .onAppear {
                        pollingForUpdates()
                    }
                    
                } else {
                    Button{
                        authModel.fetchGameData(gameCode: gameCode) { model in
                            if let model = model {
                                model.playerIDs.append(userModel!.mini)
                                self.gameModel = model
                                authModel.addAndUpdateGame(game: model) { success in
                                    print(success ? "Updated Game" : "Could not update Game")
                                }
                            } else {
                                self.gameModel = GameModel(id: "", lat: nil, long: nil, date: Date(), completed: false, numberOfHoles: 18, playerIDs: [])
                            }
                        }

                    } label: {
                        Text("Join Game")
                    }
                }
            }
        }
        
    }

    // MARK: - View Sections

    private var gameInfoSection: some View {
        Section(header: Text("Game Info")) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if gameModel.id == "" {
                    Text("Enter Code:")
                    Spacer()
                        TextField("Code", text: $gameCode)
                    } else {
                        Text("Code: ")
                        Spacer()
                        Text(gameModel.id)
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
                            .frame(width: 40, height: 40)
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Searching...")
                            .font(.caption)
                    }
                    .padding(.horizontal)
                }
            }
            .frame(height: 75)
        }
    }
    
    private func pollingForUpdates() {
        if gameModel.id != "" {
            authModel.fetchGameData(gameCode: gameModel.id) { model in
                if let model = model {
                    self.gameModel = model
                } else {
                    self.gameModel = GameModel(id: "", lat: nil, long: nil, date: Date(), completed: false, numberOfHoles: 18, playerIDs: [])
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    pollingForUpdates()
                }
            }
        }
    }
}
