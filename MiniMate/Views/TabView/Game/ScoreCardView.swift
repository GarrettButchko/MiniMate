//
//  GameView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/18/25.
//

import SwiftUI

struct ScoreCardView: View {
    @Environment(\.modelContext) private var context
    
    @Binding var userModel: UserModel?
    @StateObject var authModel: AuthModel

    var gameModel: GameModel
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isSyncing1 = false
    @State private var isSyncing2 = false
    
    @State private var uuid: UUID? = nil

    var body: some View {
        VStack{
            HStack {
                Text("Scorecard")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            
                HStack{
                    Text("Name")
                        .frame(width: 100, height: 60) // bigger cell
                        .font(.title3)                 // larger font
                        .fontWeight(.semibold)
                    
                    Divider()
                    
                    SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                        ForEach(gameModel.playerIDs) { playerID in
                            PhotoIconView(photoURL: playerID.photoURL, name: playerID.name)
                                .frame(width: 100, height: 60)
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
                                .frame(width: 100, height: 60) // wider & taller
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    
                    SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                        ForEach(gameModel.playerIDs) { playerID in
                            PlayerScoreColumnView(playerID: playerID, userModel: $userModel, gameModel: gameModel)
                        }
                    }
                }
            }
            
            Divider()
            
            Text("Total")
                .frame(width: 100, height: 60)
                .font(.title3)
                .fontWeight(.semibold)
            
        }
        .onAppear {
            guard let user = userModel else { return }

            if let existingGame = user.games.first(where: { $0.id == gameModel.id }) {
                print("🔁 Using existing gameModel from userModel.games")
                gameModel.holes = existingGame.holes // just in case we want to keep UI consistent
            } else {
                // Create fresh holes
                let newHoles = (0..<gameModel.numberOfHoles).map {
                    HoleModel(number: $0 + 1, par: 2, strokes: 0)
                }
                newHoles.forEach { context.insert($0) }

                gameModel.holes = newHoles
                context.insert(gameModel)
                userModel?.games.append(gameModel)

                print("✅ Game added and holes initialized")
            }

            try? context.save()
        }
    }
}

struct PlayerScoreColumnView: View {
    let playerID: UserModelEssentials
    @Binding var userModel: UserModel?
    let gameModel: GameModel
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack {
            if playerID.id == userModel?.id {

                if let gameIndex = userModel?.games.firstIndex(where: { $0.id == gameModel.id }) {

                    if let holes = userModel?.games[gameIndex].holes {
                        ForEach(holes.indices, id: \.self) { i in
                            NumberPickerView(
                                selectedNumber: Binding(
                                    get: { holes[i].strokes },
                                    set: { newValue in
                                        userModel?.games[gameIndex].holes[i].strokes = newValue
                                        try? context.save()
                                    }
                                ),
                                maxNumber: 10
                            )
                            .frame(height: 60)
                            Divider()
                        }
                    } else {
                        Text("🚫 Holes nil")
                    }
                } else {
                    Text("🚫 Game not found")
                }
            } else {
                Text("Player not current user")
            }
        }
        
        .frame(width: 100)
    }

}
