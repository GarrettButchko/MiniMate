// ScoreCardView.swift
// MiniMate
//
// Refactored to use SwiftData models and AuthViewModel

import SwiftUI

struct GameReviewView: View {
    @StateObject var viewManager: ViewManager
    var game: Game
    
    @State private var scrollOffset: CGFloat = 0
    @State private var uuid: UUID? = nil
    
    @State var showInfoView: Bool = false
    
    var body: some View {
        VStack {
            headerView
            scoreGridView
            footerView
        }
        .padding()
        .sheet(isPresented: $showInfoView) {
            GameInfoReviewView(viewManager: viewManager, game: game, isSheetPresent: $showInfoView)
        }
    }
    
    // MARK: Header
    private var headerView: some View {
        HStack {
            Text("Scorecard")
                .font(.title).fontWeight(.bold)
            Spacer()
            Button {
                showInfoView = true
            } label: {
                Image(systemName: "info.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
        }
    }
    
    // MARK: Score Grid
    private var scoreGridView: some View {
        VStack {
            playerHeaderRow
            Divider()
            scoreRows
            Divider()
            totalRow
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .padding(.vertical)
    }
    
    /// Player Row
    private var playerHeaderRow: some View {
        HStack {
            Text("Name")
                .frame(width: 100, height: 60)
                .font(.title3).fontWeight(.semibold)
            Divider()
            SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                HStack {
                    ForEach(game.players) { player in
                        if player.id != game.players[0].id { Divider() }
                        PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: 30, background: .ultraThinMaterial)
                            .frame(width: 100, height: 60)
                    }
                }
            }
        }
        .frame(height: 60)
        .padding(.top)
    }
    
    /// Score columns and hole icons
    private var scoreRows: some View {
        ScrollView {
            HStack(alignment: .top) {
                holeNumbersColumn
                Divider()
                SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                    PlayerColumnsShowView(game: game)
                }
            }
        }
    }
    
    /// first column with holes and number i.e "hole 1"
    private var holeNumbersColumn: some View {
        VStack {
            ForEach(1...game.numberOfHoles, id: \.self) { i in
                if i != 1 { Divider() }
                Text("Hole \(i)")
                    .font(.body).fontWeight(.medium)
                    .frame(height: 60)
            }
        }
        .frame(width: 100)
    }
    
    /// totals row
    private var totalRow: some View {
        HStack {
            Text("Total")
                .frame(width: 100, height: 60)
                .font(.title3).fontWeight(.semibold)
            Divider()
            SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                HStack {
                    ForEach(game.players) { player in
                        if player.id != game.players[0].id { Divider() }
                        Text("Total: \(player.holes.reduce(0) { $0 + $1.strokes })")
                            .frame(width: 100, height: 60)
                    }
                }
            }
        }
        .frame(height: 60)
        .padding(.bottom)
    }
    
    // MARK: Footer complete game button and timer
    private var footerView: some View {
        HStack {
            Spacer()
            Button {
                viewManager.navigateToMain(0)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.blue)
                        .frame(width: 200, height: 60)
                    Text("Back to Stats")
                        .foregroundColor(.white).fontWeight(.bold)
                }
            }
            Spacer()
            Text(timeString(from: game.totalTime))
                .frame(minWidth: 50)
            Spacer()
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - PlayerScoreColumnView

struct PlayerScoreColumnShowView: View {
    var player: Player
    
    var body: some View {
        VStack {
            ForEach(player.holes.sorted(by: { $0.number < $1.number }), id: \.number) { hole in
                            HoleRowShowView(hole: hole)
                        }
        }
    }
}

// MARK: - HoleRowView
struct HoleRowShowView: View {
    var hole: Hole
    
    var body: some View {
        VStack {
            if hole.number != 1 { Divider() }
            Text("\(hole.strokes)")
                .frame(height: 60)
        }
    }
}

struct PlayerColumnsShowView: View {
    var game: Game
    
    var body: some View {
        HStack {
            ForEach(game.players) { player in
                if player.id != game.players[0].id{
                    Divider()
                }
                PlayerScoreColumnShowView( player: player)
                    .frame(width: 100)
            }
        }
    }
}
