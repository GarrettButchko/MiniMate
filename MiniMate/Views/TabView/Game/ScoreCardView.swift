//
//  GameView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/18/25.
//

import SwiftUI

struct ScoreCardView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject var viewManager: ViewManager
    
    @Binding var userModel: UserModel?
    @StateObject var authModel: AuthModel

    @Binding var gameModel: GameModel
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isSyncing1 = false
    @State private var isSyncing2 = false
    
    @State private var sum: Int? = 0
    
    @State private var uuid: UUID? = nil
    
    @State var addedHoles = false
    
    @State private var playerTotals: [String: Int] = [:]

    var body: some View {
        VStack{
            HStack {
                Text("Scorecard")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(gameModel.id)")
            }
            
            
                HStack{
                    Text("Name")
                        .frame(width: 100, height: 60) // bigger cell
                        .font(.title3)                 // larger font
                        .fontWeight(.semibold)
                    
                    Divider()
                    
                    SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                        HStack{
                            ForEach(gameModel.playerIDs) { playerID in
                                if playerID.id != userModel?.id{
                                    Divider()
                                }
                                PhotoIconView(photoURL: playerID.photoURL, name: playerID.name)
                                    .frame(width: 100, height: 60)
                            }
                        }
                    }
                }
                .frame(height: 60)
            
            
            
            
            Divider()
            
            ScrollView(){
                HStack{
                    VStack() {
                        ForEach(1...gameModel.numberOfHoles, id: \.self) { i in
                            if i != 1{
                                Divider()
                            }
                            Text("Hole \(i)")
                                .font(.body)
                                .fontWeight(.medium)
                                .frame(height: 60)
                        }
                    }
                    .frame(width: 100) // wider & taller
                    
                    Divider()
                    
                    SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                        HStack {
                            ForEach($gameModel.playerIDs) { $playerID in
                                
                                if playerID.id != userModel?.id{
                                    Divider()
                                }
                                PlayerScoreColumnView(playerID: $playerID, gameModel: gameModel, authModel: authModel) { total in
                                    playerTotals[playerID.id] = total
                                    authModel.addOrUpdateGame(gameModel) { _ in }
                                } outHoles: { holes in
                                    playerID.holes = holes
                                    authModel.addOrUpdateGame(gameModel) { _ in }
                                }
                                .frame(width: 100)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            HStack{
                Text("Total")
                    .frame(width: 100, height: 60)
                    .font(.title3)
                    .fontWeight(.semibold)
                 
                Divider()
                
                SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                    HStack {
                        ForEach(gameModel.playerIDs) { playerID in
                            if playerID.id != userModel?.id{
                                Divider()
                            }
                            Text("Total: \(playerTotals[playerID.id] ?? -1)")  // <-- Dynamic lookup
                                .frame(width: 100, height: 60)
                        }
                    }
                }
                .id(playerTotals)
            }
            .frame(height: 60)
        }
        .onAppear {
            
            for playerID in gameModel.playerIDs {
                context.insert(playerID)
            }
            context.insert(gameModel)
            
            userModel?.games.append(gameModel)
            
            // 🛡️ 🔥 Always clean playerIDs before save!
            gameModel.playerIDs = gameModel.playerIDs.filter {
                !$0.id.isEmpty && !$0.name.isEmpty
            }
            
            /// Saved to all places
            try? context.save()
            authModel.saveUserData(userModel!) { _ in }
            authModel.addOrUpdateGame(gameModel) { _ in }
            
            addedHoles = true
            
            pollingForUpdates()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive {
                dismissal()
            }
        }
        .padding()
    }
    
    private func dismissal() {
        if !gameModel.completed {
            gameModel.playerIDs.removeAll { $0.id == userModel?.mini.id }
            authModel.deleteGameData(gameCode: gameModel.id) { _ in }
            viewManager.navigateToMain()
        }
    }
    
    private func pollingForUpdates() {
        authModel.fetchGameData(gameCode: gameModel.id) { model in
            if let model = model {
                self.gameModel = model
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                pollingForUpdates()
            }
        }
    }
}

struct PlayerScoreColumnView: View {
    @Binding var playerID: UserModelEssentials
    let gameModel: GameModel
    @StateObject var authModel: AuthModel
    
    var onTotalChange: (Int) -> Void  // <-- Callback to parent view
    var outHoles: ([HoleModel]) -> Void
    
    
    @Environment(\.modelContext) private var context
    @State var holes: [HoleModel] = []
    
    var body: some View {
        VStack {
            ForEach($holes) { $hole in
                if hole.number != 1 {
                    Divider()
                }
                NumberPickerView(selectedNumber: $hole.strokes, maxNumber: 10)
                    .onChange(of: hole.strokes) { _, _ in
                        updateTotalStrokes()
                    }
                    .frame(height: 60)
            }
        }
        .onAppear {
            let newHoles = (0..<gameModel.numberOfHoles).map {
                HoleModel(number: $0 + 1, par: 2, strokes: 0)
            }
            
            holes = newHoles
            playerID.holes = holes
            updateTotalStrokes()  // Initialize total
            
            pollingForHoleUpdates()
        }
    }
    
    private func updateTotalStrokes() {
        let total = holes.reduce(0) { $0 + $1.strokes }
        playerID.totalStrokes = total
        onTotalChange(total)  // <-- Notify ScoreCardView
        outHoles(holes)
    }
    
    private func pollingForHoleUpdates() {
        authModel.fetchGameData(gameCode: gameModel.id) { model in
            holes = model?.playerIDs.first(where: { $0.id == self.playerID.id })?.holes ?? []
            updateTotalStrokes()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                pollingForHoleUpdates()
            }
        }
    }
}
