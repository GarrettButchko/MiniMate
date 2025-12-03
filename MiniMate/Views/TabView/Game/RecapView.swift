//
//  RecapView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/12/25.
//
import SwiftUI
import ConfettiSwiftUI

struct RecapView<VM: ViewManager & ObservableObject, AM: ObservableObject, Content: View>: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var authModel: AM
    @StateObject var viewManager: VM
    
    @State var confettiTrigger: Bool = false
    @State var showReviewSheet: Bool = false
    @State var showLeaderBoardAlert: Bool = false
    
    @State var email: String = ""
    
    let course: Course?
    
    let game: Game?
    
    var sortedPlayers: [Player] {
        guard let game = game else { return [] }

        let players = game.players.sorted { $0.totalStrokes < $1.totalStrokes }
        return players.isEmpty ? [] : players
    }
    
    let content: () -> Content
    
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
                        VStack{
                            HStack{
                                PhotoIconView(photoURL: sortedPlayers[0].photoURL, name: sortedPlayers[0].name + "🥇", imageSize: 70, background: Color.yellow)
                                Spacer()
                                Text(sortedPlayers[0].totalStrokes.description)
                                    .font(.title)
                                    .foregroundStyle(Color.yellow)
                                    .padding()
                            }
                            AddToLeaderBoardButton(course: course, player: sortedPlayers[0])
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                        
                        
                        
                        HStack{
                            VStack{
                                HStack{
                                    PhotoIconView(photoURL: sortedPlayers[1].photoURL, name: sortedPlayers[1].name + "🥈", imageSize: 40, background: Color.gray)
                                    Spacer()
                                    Text(sortedPlayers[1].totalStrokes.description)
                                        .font(.title)
                                        .foregroundStyle(Color.gray)
                                        .padding()
                                }
                                AddToLeaderBoardButton(course: course, player: sortedPlayers[1])
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                            
                            if sortedPlayers.count > 2{
                                VStack{
                                    HStack{
                                        PhotoIconView(photoURL: sortedPlayers[2].photoURL, name: sortedPlayers[2].name + "🥉", imageSize: 40, background: Color.brown)
                                        Spacer()
                                        Text(sortedPlayers[2].totalStrokes.description)
                                            .font(.title)
                                            .foregroundStyle(Color.brown)
                                            .padding()
                                    }
                                    AddToLeaderBoardButton(course: course, player: sortedPlayers[2])
                                }
                                .padding()
                                .background(Color.brown.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                            }
                        }
                        
                        
                        
                        if sortedPlayers.count > 3 {
                            ScrollView{
                                ForEach(sortedPlayers[3...]) { player in
                                    VStack{
                                        HStack{
                                            PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: 30, background: .ultraThinMaterial)
                                            Spacer()
                                            Text(player.totalStrokes.description)
                                                .font(.subheadline)
                                                .padding()
                                        }
                                        AddToLeaderBoardButton(course: course, player: player)
                                    }
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                                }
                            }
                            .frame(height: geometry.size.height * 0.3)
                        }
                        
                        
                    } else {
                        VStack{
                            HStack{
                                PhotoIconView(photoURL: sortedPlayers[0].photoURL, name: sortedPlayers[0].name, imageSize: 70, background: .ultraThinMaterial)
                                
                                Spacer()
                                
                                Text(sortedPlayers[0].totalStrokes.description)
                                    .font(.title)
                                    .padding()
                            }
                            AddToLeaderBoardButton(course: course, player: sortedPlayers[0])
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                        
                    }
                    
                    if sortedPlayers.count <= 3 {
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
                        if let game = game {
                            GameReviewView(viewManager: viewManager, game: game)
                        }
                    }
                    content()
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

