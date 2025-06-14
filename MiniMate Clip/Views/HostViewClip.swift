// HostView.swift
// MiniMate
//
// Refactored to use new SwiftData models and AuthViewModel

import SwiftUI
import MapKit

struct HostViewClip: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    let course: Course?

    @Binding var showHost: Bool

    @ObservedObject var authModel: AuthViewModelClip
    @ObservedObject var viewManager: ViewManagerClip
    @ObservedObject var gameModel: GameViewModelClip

    @State private var showAddPlayerAlert = false
    @State private var showDeleteAlert = false
    @State private var newPlayerName = ""
    @State private var playerToDelete: String?
    
    // how long (in seconds) a game stays live without activity
    private let ttl: TimeInterval = 20 * 60
    // when this game was last pushed to Firebase
    @State private var lastUpdated: Date = Date()
    // a one-second ticker
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State  private var timeRemaining: TimeInterval = 20 * 60
    
    @State var showLocationPicker: Bool = false

    var body: some View {
        VStack {
            Capsule()
                .frame(width: 38, height: 6)
                .foregroundColor(.gray)
                .padding(10)

            HStack {
                Text("Game Setup")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 30)
                Spacer()
            }

            Form {
                    Group {
                        Section {
                            if let name = course?.name {
                                HStack {
                                    Text("Location:")
                                    Spacer()
                                    Text(name)
                                }
                            } else {
                                EmptyView()
                            }
                            if course != nil {
                                EmptyView()
                            } else {
                                HStack {
                                    Text("Holes:")
                                    NumberPickerView(
                                        selectedNumber: gameModel.binding(for: \.numberOfHoles),
                                        minNumber: 9, maxNumber: 21
                                    )
                                }
                            }
                        } header: {
                            Text("Game Info")
                        }
                    }
                
                playersSection
                startGameSection
            }
        }
        .onChange(of: showHost) { _, newValue in
            if !newValue && !gameModel.started {
                gameModel.dismissGame()
            }
        }
        .alert("Add Local Player?", isPresented: $showAddPlayerAlert) {
            TextField("Name", text: $newPlayerName)
                .characterLimit($newPlayerName, maxLength: 18)
                //.profanityFilter(text: $newPlayerName)
            Button("Add") { gameModel.addLocalPlayer(named: newPlayerName)}
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Player?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let player = playerToDelete {
                    gameModel.removePlayer(userId: player)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onReceive(ticker) { _ in
          // compute seconds until (lastUpdated + ttl)
          let expireDate = lastUpdated.addingTimeInterval(ttl)
          timeRemaining = max(0, expireDate.timeIntervalSinceNow)
          
          // if we’ve actually hit zero, you could auto-dismiss:
          if timeRemaining <= 0 {
            showHost = false
          }
        }
    }


    // MARK: – Composed Section
    private var playersSection: some View {
        Section(header: Text("Players: \(gameModel.gameValue.players.count)")) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(gameModel.gameValue.players) { player in
                        PlayerIconView(player: player, isRemovable: player.userId.count == 6) {
                            playerToDelete = player.userId
                            showDeleteAlert = true
                        }
                    }
                    Button(action: { newPlayerName = ""; showAddPlayerAlert = true }) {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "plus")
                            }
                            Text("Add Player").font(.caption)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(height: 75)
        }
    }

    private var startGameSection: some View {
        Section {
            Button("Start Game") {
                gameModel.startGame(showHost: $showHost)
                viewManager.navigateToScoreCard()
            }
        }
    }


    // MARK: - Logic
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct MapItemPickerRowView: View {
    let item: MKMapItem
    let userLocation: CLLocationCoordinate2D

    var body: some View {
        let itemName = item.name ?? "Unknown"
        let itemLocation = CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude)
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distanceInMiles = userLoc.distance(from: itemLocation) / 1609.34

        Text("\(itemName) • \(String(format: "%.1f", distanceInMiles)) mi")
    }
}

// MARK: - Player Icon View

struct PlayerIconView: View {
    let player: Player
    var isRemovable: Bool
    var onTap: (() -> Void)?
    var imageSize: CGFloat = 30

    var body: some View {
        Group {
            if isRemovable {
                Button {
                    onTap?()
                } label: {
                    PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: imageSize, background: .ultraThinMaterial)
                }
            } else {
                PhotoIconView(photoURL: player.photoURL, name: player.name, imageSize: imageSize, background: .ultraThinMaterial)
            }
        }
        .padding(.horizontal)
    }
}
