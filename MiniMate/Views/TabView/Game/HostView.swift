// HostView.swift
// MiniMate
//
// Refactored to use new SwiftData models and AuthViewModel

import SwiftUI
import MapKit

struct HostView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @Binding var showHost: Bool

    @ObservedObject var authModel: AuthViewModel
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var locationHandler: LocationHandler
    @ObservedObject var gameModel: GameViewModel

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
                Text(gameModel.onlineGame ? "Hosting Game" : "Game Setup")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.leading, 30)
                Spacer()
            }

            Form {
                gameInfoSection
                playersSection
                startGameSection
            }
        }
        .onChange(of: showHost) { _, newValue in
            if !newValue {
                gameModel.dismissGame()
            }
        }
        .alert("Add Local Player?", isPresented: $showAddPlayerAlert) {
            TextField("Name", text: $newPlayerName)
            Button("Add") { gameModel.addLocalPlayer(named: newPlayerName)}
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Player?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let player = playerToDelete {
                    gameModel.removePlayer(id: player)
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

    // MARK: - Sections

    private var gameInfoSection: some View {
        Group {
            Section {
                if gameModel.onlineGame {
                    HStack {
                        Text("Game Code:")
                        Spacer()
                        Text(gameModel.gameValue.id)
                    }

                    HStack {
                        Text("Expires in:")
                        Spacer()
                        Text(timeString(from: Int(timeRemaining)))
                            .monospacedDigit()
                    }
                }

                DatePicker("Date & Time", selection: gameModel.binding(for: \.date))
                    

                locationSection

                HStack {
                    Text("Holes:")
                    NumberPickerView(
                        selectedNumber: gameModel.binding(for: \.numberOfHoles),
                        minNumber: 9, maxNumber: 21
                    )
                }

            } header: {
                Text("Game Info")
            }
        }
    }

    private var locationSection: some View {
        Group{
            if gameModel.onlineGame {
                HStack {
                    Text("Use Location:")
                    Spacer()
                    Toggle("", isOn: $showLocationPicker)
                        .onChange(of: showLocationPicker) { _, new in
                            if new, let userCoord = locationHandler.userLocation {
                                locationHandler.setClosestValue()
                                
                                let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
                                locationHandler.mapItems = locationHandler.mapItems.sorted {
                                    let loc1 = CLLocation(latitude: $0.placemark.coordinate.latitude,
                                                          longitude: $0.placemark.coordinate.longitude)
                                    let loc2 = CLLocation(latitude: $1.placemark.coordinate.latitude,
                                                          longitude: $1.placemark.coordinate.longitude)
                                    return loc1.distance(from: userLoc) < loc2.distance(from: userLoc)
                                }
                                
                            } else {
                                gameModel.setLocation(MapItemDTO(latitude: 0, longitude: 0, name: nil, phoneNumber: nil, url: nil, poiCategory: nil, timeZone: nil, street: nil, city: nil, state: nil, postalCode: nil, country: nil))
                                locationHandler.setSelectedItem(nil)
                            }
                        }
                }
            }
            
            if showLocationPicker, let userLocation = locationHandler.userLocation {
                
                VStack{
                    Text("Select a Course:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: locationHandler.bindingForSelectedItemID()) {
                        ForEach(locationHandler.mapItems, id: \.idString) { item in
                            MapItemPickerRowView(item: item, userLocation: userLocation)
                                .tag(item.idString)
                        }
                    }
                    .pickerStyle(.wheel)
                    .onChange(of: locationHandler.bindingForSelectedItemID().wrappedValue) {_ ,  newID in
                        // newID is a String? — either the selected id, or nil if cleared
                        if let id = newID,
                           let selected = locationHandler.mapItems.first(where: { $0.idString == id }) {
                          // convert your MKMapItem into your DTO and write it into the game VM
                            gameModel.setLocation(selected.toDTO())
                            gameModel.pushUpdate()
                        }
                      }
                }
            }
        }
    }

    private var playersSection: some View {
        Section(header: Text("Players: \(gameModel.gameValue.players.count)")) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(gameModel.gameValue.players) { player in
                        PlayerIconView(player: player, isRemovable: player.id.count == 6) {
                            playerToDelete = player.id
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
                    if gameModel.onlineGame {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(width: 40, height: 40)
                            Text("Searching...").font(.caption)
                        }.padding(.horizontal)
                    }
                }
            }
            .frame(height: 75)
        }
    }

    private var startGameSection: some View {
        Section {
            Button("Start Game") {
                gameModel.startGame()
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
