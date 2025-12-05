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
    @State private var newPlayerEmail = ""
    @State private var playerToDelete: String?
    
    // how long (in seconds) a game stays live without activity
    private let ttl: TimeInterval = 20 * 60
    // when this game was last pushed to Firebase
    @State private var lastUpdated: Date = Date()
    // a one-second ticker
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State  private var timeRemaining: TimeInterval = 20 * 60
    
    @State var showTextAndButtons: Bool = false
    
    @State private var isRotating = false // Place this in your view struct
    
    let courseRepo = CourseRepository()
    
    var body: some View {
        VStack {
            Capsule()
                .frame(width: 38, height: 6)
                .foregroundColor(.gray)
                .padding(10)
            
            HStack {
                Text(gameModel.isOnline ? "Hosting Game" : "Game Setup")
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
            if !newValue && !gameModel.started {
                gameModel.dismissGame()
            }
        }
        .alert("Add Local Player?", isPresented: $showAddPlayerAlert) {
            
            TextField("Name", text: $newPlayerName)
                .characterLimit($newPlayerName, maxLength: 18)
            
            if gameModel.getCourse() != nil {
                TextField("Email", text: $newPlayerEmail)
                    .autocapitalization(.none)   // starts lowercase / no auto-cap
                    .keyboardType(.emailAddress)
            }
                
            Button("Add") {
                gameModel.addLocalPlayer(named: newPlayerName, email: newPlayerEmail)
                newPlayerName = "";
                newPlayerEmail = "";
            }
            .disabled(
                newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !newPlayerEmail.isEmpty
            )
            .tint(.blue)
            
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
    
    // MARK: - Sections
    private var gameInfoSection: some View {
        Group {
            Section {
                if gameModel.isOnline {
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
                    .onChange(of: locationHandler.selectedItem) { _, newValue in
                        guard
                            let newValue = newValue,
                            let name = newValue.name
                        else { return }

                        courseRepo.courseNameExistsAndSupported(name) { exists in
                            if !exists {
                                return
                            }

                            // Course exists — try to fetch it
                            courseRepo.fetchCourseByName(name) { course in
                                
                                let holeCount = course?.pars?.count ?? 18
                                    gameModel.setNumberOfHole(holeCount)
                                
                            }
                        }
                    }

                
                if locationHandler.hasLocationAccess{
                    locationSection
                }
                
                if let course = gameModel.getCourse() {
                    if course.pars == nil {
                        HStack {
                            Text("Holes:")
                            NumberPickerView(
                                selectedNumber: gameModel.binding(for: \.numberOfHoles),
                                minNumber: 9, maxNumber: 21
                            )
                        }
                    }
                } else {
                    // No course → show picker
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
    }
    
    
    // MARK: – Composed Section
    
    private var locationSection: some View {
        Group {
            if NetworkChecker.shared.isConnected {
                HStack{
                    VStack{
                        HStack{
                            Text("Location:")
                            Spacer()
                        }
                        if showTextAndButtons {
                            if let item = locationHandler.selectedItem {
                                HStack{
                                    Text(item.name ?? "Unnamed")
                                        .foregroundStyle(.secondary)
                                        .truncationMode(.tail)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                    Spacer()
                                }
                            } else {
                                HStack{
                                    Text("No location found")
                                        .foregroundStyle(.secondary)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if !showTextAndButtons {
                        
                        Button {
                            
                            gameModel.setHasLoaded(false)
                            gameModel.findClosestLocationAndLoadCourse(locationHandler: locationHandler, showTextAndButtons: $showTextAndButtons)
                            
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                Text("Search Nearby")
                            }
                            .frame(width: 180, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        
                        
                        // Retry Button
                        Button(action: {
                            withAnimation(){
                                isRotating = true
                            }
                            
                            gameModel.setHasLoaded(false)
                            gameModel.findClosestLocationAndLoadCourse(locationHandler: locationHandler, showTextAndButtons: $showTextAndButtons)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isRotating = false
                            }
                        }) {
                            Image(systemName: "arrow.trianglehead.2.clockwise")
                                .rotationEffect(.degrees(isRotating ? 360 : 0))
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        
                        
                        
                        // Exit Button
                        Button(action: {
                            withAnimation {
                                locationHandler.selectedItem = nil
                                gameModel.setLocation(nil)
                                gameModel.resetCourse()
                                showTextAndButtons = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .onAppear {
                    if gameModel.getCourse() == nil && !gameModel.getHasLoaded() {
                        gameModel.findClosestLocationAndLoadCourse(locationHandler: locationHandler, showTextAndButtons: $showTextAndButtons)
                        gameModel.setHasLoaded(true)
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
                        PlayerIconView(player: player, isRemovable: player.userId.count == 6) {
                            playerToDelete = player.userId
                            showDeleteAlert = true
                        }
                    }
                    Button(action: { showAddPlayerAlert = true }) {
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
                    if gameModel.isOnline {
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
