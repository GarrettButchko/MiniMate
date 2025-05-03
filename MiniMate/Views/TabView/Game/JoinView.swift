// JoinView.swift
// MiniMate
//
// Refactored to use SwiftData models and AuthViewModel

import SwiftUI

struct JoinView: View {
    @Environment(\.modelContext) private var context
   
    @ObservedObject var authModel: AuthViewModel
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var gameModel: GameViewModel

    @State private var gameCode: String = ""
    @State private var message: String = ""
    
    @Binding var showHost: Bool
    @State var inGame: Bool = false
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

                if inGame {
                    Group{
                        playersSection
                        Section {
                            Button("Exit Game") {
                                showExitAlert = true
                            }
                            .foregroundColor(.red)
                            .alert("Exit Game?", isPresented: $showExitAlert) {
                                Button("Leave", role: .destructive) {
                                    gameModel.leaveGame(userId: authModel.userModel!.id)
                                    gameCode = ""
                                    inGame = false
                                }
                                Button("Cancel", role: .cancel) {}
                            }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                } else {
                    Section {
                        Button("Join Game") {
                            gameModel.joinGame(id: gameCode){ result in
                                if result {
                                    withAnimation{
                                        inGame = true
                                    }
                                }
                            }
                        }
                        .disabled(gameCode.isEmpty)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: showHost) { oldValue, newValue in
            if !gameModel.gameValue.id.isEmpty && !showHost && !gameModel.gameValue.started {
                gameModel.leaveGame(userId: gameModel.gameValue.id)
                withAnimation{
                    inGame = false
                }
            }
        }
        .onChange(of: gameModel.gameValue.started) { oldValue, newValue in
            if newValue {
                viewManager.navigateToScoreCard()
            }
        }
        .onChange(of: gameModel.gameValue.dismissed) { oldValue, newValue in
            if newValue {
                gameCode = ""
                withAnimation{
                    inGame = false
                }
            }
        }
    }

    // MARK: - Sections

    private var gameInfoSection: some View {
        Section(header: Text("Game Info")) {
            if !inGame {
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
                    Text(gameModel.gameValue.id)
                }
                HStack {
                    Text("Date:")
                    Spacer()
                    Text(gameModel.gameValue.date.formatted(date: .abbreviated, time: .shortened))
                }
                
                if let gameModel = gameModel.gameValue.location, gameModel.latitude != 0 {
                    HStack {
                        Text("Location:")
                        Spacer()
                        Text(gameModel.name!)
                    }
                }
                
                HStack {
                    Text("Holes:")
                    Spacer()
                    Text("\(gameModel.gameValue.numberOfHoles)")
                }
            }
        }
    }

    private var playersSection: some View {
        Section(header: Text("Players: \(gameModel.gameValue.players.count)")) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(gameModel.gameValue.players) { player in
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
}
