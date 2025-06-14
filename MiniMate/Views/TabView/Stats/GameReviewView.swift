// ScoreCardView.swift
// MiniMate
//
// Refactored to use SwiftData models and AuthViewModel

import SwiftUI

struct GameReviewView<ViewManagerType: NavigatableViewManager>: View {
    @StateObject var viewManager: ViewManagerType
    var game: Game
    let course: Course?
    
    let isAppClip: Bool
    
    @State private var scrollOffset: CGFloat
    @State private var uuid: UUID?
    @State private var showInfoView: Bool
    
    // Custom init to assign @StateObject and normal vars
    init(viewManager: ViewManagerType, game: Game, course: Course? = nil, isAppClip: Bool = false, scrollOffset: CGFloat = 0, uuid: UUID? = nil, showInfoView: Bool = false) {
        _viewManager = StateObject(wrappedValue: viewManager)
        self.game = game
        print(game.courseID as Any)
        self.course = course
        self.isAppClip = isAppClip
        _scrollOffset = State(initialValue: scrollOffset)
        _uuid = State(initialValue: uuid)
        _showInfoView = State(initialValue: showInfoView)
    }
    
    var body: some View {
        VStack {
            headerView
            scoreGridView
            footerView
        }
        .padding()
        .sheet(isPresented: $showInfoView) {
            GameInfoReviewView(game: game, isSheetPresent: $showInfoView)
        }
    }
    
    // MARK: Header
    private var headerView: some View {
        VStack{
            if isAppClip{
                Capsule()
                    .frame(width: 38, height: 6)
                    .foregroundColor(.gray)
            }
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
        .background(
            course?.colors.first.map { AnyShapeStyle($0.opacity(0.2))} ?? AnyShapeStyle(.ultraThinMaterial)
        )
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
                VStack{
                    Text("Hole \(i)")
                        .font(.body).fontWeight(.medium)
                    if let course = course, course.hasPars {
                        Text("Par: \(course.pars[i - 1])")
                            .font(.caption)
                    }
                }
                .frame(height: 60)
            }
        }
        .frame(width: 100)
    }
    
    /// totals row
    private var totalRow: some View {
        HStack {
            VStack{
                Text("Total")
                    .font(.title3).fontWeight(.semibold)
                if let course = course, course.hasPars {
                    Text("Par: \(course.pars.reduce(0, +))")
                        .font(.caption)
                }
            }
            .frame(width: 100, height: 60)
            Divider()
            SyncedScrollViewRepresentable(scrollOffset: $scrollOffset, syncSourceID: $uuid) {
                HStack {
                    ForEach(game.players) { player in
                        if player.id != game.players[0].id { Divider() }
                        Text("Total: \(player.totalStrokes)")
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
        
        
        ZStack{
            HStack{
                if !isAppClip {
                    Spacer()
                }
                  ShareLink(item: makeShareableSummary(for: game)) {
                    Image(systemName: "square.and.arrow.up")
                          .font(.title2)
                  }
                  .padding()
            }
            if !isAppClip {
                HStack {
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
                }
            }
        }
        .padding(.bottom)
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    /// Build a plain-text summary (you could also return a URL to a generated PDF/image)
    func makeShareableSummary(for game: Game) -> String {
      var lines = ["MiniMate Scorecard",
                   "Date: \(game.date.formatted(.dateTime))",
                   ""]
      
      for player in game.players {
          var holeLine = ""
          
          for hole in player.holes {
                holeLine += "|\(hole.strokes)"
          }
          
          lines.append("\(player.name): \(player.totalStrokes) strokes (\(player.totalStrokes))")
          lines.append("Holes " + holeLine)
          
      }
      lines.append("")
      lines.append("Download MiniMate: https://apps.apple.com/app/id6745438125")
      return lines.joined(separator: "\n")
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
