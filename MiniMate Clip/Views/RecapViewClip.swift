//
//  RecapView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/12/25.
//
import SwiftUI
import ConfettiSwiftUI

struct RecapView: View {
    var userModel: UserModel
    @StateObject var viewManager: ViewManagerClip
    @State var confettiTrigger: Bool = false
    @State var showReviewSheet: Bool = false
    var sortedPlayers: [Player] {
        let players = userModel.games.sorted(by: { $0.date > $1.date }).first!.players.sorted(by: { $0.totalStrokes < $1.totalStrokes })
        if players.count > 1 {
            return players
        } else {
            return [userModel.games.sorted(by: { $0.date > $1.date }).first!.players[0]]
        }
    }
    
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack{
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(spacing: 10){
                    Spacer()
                    Text("Review of Game")
                        .font(.subheadline)
                        .opacity(0.5)
                    Text("Congratulations!")
                        .font(.largeTitle)
                    
                    Spacer()
                    
                    if sortedPlayers.count > 1 {
                        
                        HStack{
                            PhotoIconView(photoURL: sortedPlayers[0].photoURL, name: sortedPlayers[0].name + "🥇", imageSize: 70, background: Color.yellow)
                            Spacer()
                            Text(sortedPlayers[0].totalStrokes.description)
                                .font(.title)
                                .foregroundStyle(Color.yellow)
                                .padding()
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                        
                        
                        
                        HStack{
                            HStack{
                                PhotoIconView(photoURL: sortedPlayers[1].photoURL, name: sortedPlayers[1].name + "🥈", imageSize: 40, background: Color.gray)
                                Spacer()
                                Text(sortedPlayers[1].totalStrokes.description)
                                    .font(.title)
                                    .foregroundStyle(Color.gray)
                                    .padding()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                            
                            if sortedPlayers.count > 2{
                                HStack{
                                    PhotoIconView(photoURL: sortedPlayers[2].photoURL, name: sortedPlayers[2].name + "🥉", imageSize: 40, background: Color.brown)
                                    Spacer()
                                    Text(sortedPlayers[2].totalStrokes.description)
                                        .font(.title)
                                        .foregroundStyle(Color.brown)
                                        .padding()
                                }
                                .padding()
                                .background(Color.brown.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                            }
                        }
                        
                        
                        
                        if sortedPlayers.count > 3 {
                            ScrollView{
                                ForEach(sortedPlayers[3...]) { player in
                                    HStack{
                                        PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: 30, background: .ultraThinMaterial)
                                        Spacer()
                                        Text(player.totalStrokes.description)
                                            .font(.subheadline)
                                            .padding()
                                    }
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                                }
                            }
                            .frame(height: geometry.size.height * 0.15)
                        }
                        
                        
                    } else {
                        HStack{
                            PhotoIconView(photoURL: sortedPlayers[0].photoURL, name: sortedPlayers[0].name, imageSize: 70, background: .ultraThinMaterial)
                            Spacer()
                            Text(sortedPlayers[0].totalStrokes.description)
                                .font(.title)
                                .padding()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                        
                    }
                    if sortedPlayers.count < 3 {
                        Spacer()
                        Spacer()
                    }
                    
                    Button{
                        showReviewSheet = true
                    } label: {
                        ZStack{
                            RoundedRectangle(cornerRadius: 25)
                                .foregroundStyle(Color.blue)
                            Text("Review Game")
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 140, height: 40)
                    .sheet(isPresented: $showReviewSheet){
                        GameReviewView(viewManager: viewManager, game: userModel.games.sorted(by: { $0.date > $1.date }).first!, isAppClip: true)
                    }
                    
                    
                    
                        if let game = userModel.games.sorted(by: { $0.date > $1.date }).first, game.courseID == "FC" && game.holeInOneLastHole{
                            HStack{
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Get your free Blizzard!")
                                        .foregroundStyle(.mainOpp)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text("Because you got a hole in one on the last hole, we're giving you a free Blizzard!")
                                        .foregroundStyle(.mainOpp)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .padding(.trailing)
                                }
                                Spacer()
                                Image("shake")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Spacer()
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                        
                        Button {
                            if let url = URL(string: "https://apps.apple.com/app/id6745438125") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack{
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Download Full App Now!")
                                        .foregroundStyle(.mainOpp)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Text("Tap here to download the full MiniMate app to save your progress and track your scores across multiple rounds!")
                                        .foregroundStyle(.mainOpp)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .padding(.trailing)
                                }
                                Spacer()
                                Image("Icon")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Spacer()
                            }
                            .padding()
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .padding(.bottom)
                    
                }
                .confettiCannon(trigger: $confettiTrigger, num: 40, confettis: [.shape(.slimRectangle)])
                .onAppear {
                    
                    confettiTrigger = true
                }
                .padding()
            }
        }
    }
}
