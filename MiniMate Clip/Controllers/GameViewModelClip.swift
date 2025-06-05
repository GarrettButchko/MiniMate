//
//  GameViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/1/25.
//


import Foundation
import SwiftUI
import MapKit
import Combine
import SwiftData

@dynamicMemberLookup
final class GameViewModelClip: ObservableObject {
    // MARK: - Published Game State
    
    @Published private var game: Game
    private var authModel: AuthViewModelClip
    
    // MARK: - Dependencies & Config
    private var lastUpdated: Date = Date()
    
    // MARK: - Initialization
    init(auth: AuthViewModelClip, game: Game)
    {
        self.authModel = auth
        self.game = game
    }
    
    // MARK: - Dynamic Member Lookup
    /// Read-only access: vm.someField == game.someField
    subscript<T>(dynamicMember keyPath: KeyPath<Game, T>) -> T {
        game[keyPath: keyPath]
    }
    
    /// A two‐way `Binding<Game>` for the entire model.
    func bindingForGame() -> Binding<Game> {
        Binding<Game>(
            get: { self.game },            // read the current game
            set: { newGame in              // when it’s written…
                self.setGame(newGame)        // swap in & re-attach listeners
            }
        )
    }
    
    /// Two-way binding: DatePicker(..., selection: vm.binding(for: \ .date))
    func binding<T>(for keyPath: ReferenceWritableKeyPath<Game, T>) -> Binding<T> {
        Binding(
            get: { self.game[keyPath: keyPath] },
            set: { newValue in
                self.objectWillChange.send()
                self.game[keyPath: keyPath] = newValue
            }
        )
    }
    
    /// Expose full model if needed
    // MARK: Alter Game
    var gameValue: Game { game }
    
    
    // MARK: - Public Actions
    func resetGame() {
        setGame(Game())
        
    }
    
    func setGame(_ newGame: Game) {
        objectWillChange.send()
        // Always start fresh: remove local players and holes
        game.players.removeAll()
        
        // 1) Merge top-level fields
        game.id            = newGame.id
        game.location      = newGame.location
        game.date          = newGame.date
        game.completed     = newGame.completed
        game.numberOfHoles = newGame.numberOfHoles
        game.started       = newGame.started
        game.dismissed     = newGame.dismissed
        game.live          = newGame.live
        game.lastUpdated   = newGame.lastUpdated
        lastUpdated        = newGame.lastUpdated
        game.courseID      = newGame.courseID
        
        // 2) Rebuild players and their holes from remote data
        for remotePlayer in newGame.players {
            initializeHoles(for: remotePlayer)
            // remotePlayer.holes already contains correct strokes
            // Append the fully initialized player
            game.players.append(remotePlayer)
        }
    }
    
    func setCompletedGame(_ completedGame: Bool) {
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        self.game.completed = completedGame
        
    }
    
    func setLocation(_ location: MapItemDTO) {
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        self.game.location = location
    }
    
    // MARK: - Helpers
    private func initializeHoles(for player: Player) {
        guard player.holes.count != game.numberOfHoles else { return }
        player.holes = []
        if let course = CourseResolver.resolve(id: game.courseID), course.hasPars {
            player.holes = course.holes
        } else {
            player.holes = (0..<game.numberOfHoles).map {
                let hole = Hole(number: $0 + 1, par: 2)
                hole.player = player
                return hole
            }
        }
    }
    
    private func generateGameCode(length: Int = 6) -> String {
        let chars = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
    
    // MARK: Players
    func addLocalPlayer(named name: String) {
        objectWillChange.send()
        let newPlayer = Player(
            userId: generateGameCode(),
            name: name,
            photoURL: nil,
            inGame: true
        )
        initializeHoles(for: newPlayer)
        withAnimation(){
            game.players.append(newPlayer)
        }
    }
    
    func addUser() {
        guard let user = authModel.userModel else { return }
        // don’t add the same user twice
        guard !game.players.contains(where: { $0.userId == user.id }) else { return }
        
        objectWillChange.send()
        let newPlayer = Player(
            userId: user.id,
            name: user.name,
            photoURL: user.photoURL,
            inGame: true
        )
        initializeHoles(for: newPlayer)
        withAnimation(){
            game.players.append(newPlayer)
        }
    }
    
    
    func removePlayer(userId: String) {
        objectWillChange.send()
        withAnimation(){
            game.players.removeAll { $0.userId == userId }
        }
    }
    
    func leaveGame(userId: String) {
        objectWillChange.send()
        self.removePlayer(userId: userId)
        resetGame()
    }
    
    
    // MARK: Game State
    
    func createGame(online: Bool ,startingLoc: MKMapItem?) {
        guard !game.live else { return }
        objectWillChange.send()
        print("Starting Game...: \(game.numberOfHoles)")
        game.live = true
        game.id = generateGameCode()
        addUser()
    }
    
    func startGame(showHost: Binding<Bool>) {
        guard !game.started else { return }
        
        objectWillChange.send()
        for player in game.players {
            initializeHoles(for: player)
        }
        game.started = true
        
        // Flip the binding to false
        showHost.wrappedValue = false
        
        
    }
    
    
    // MARK: Game State
    func dismissGame() {
        guard !game.dismissed else { return }
        objectWillChange.send()
        game.dismissed = true
        
        resetGame()             // now creates a new Game with id == ""
    }
    
    
    /// Deep-clone the game you just finished, persist it locally & remotely, then reset.
    func finishAndPersistGame(in context: ModelContext) {
        
        // Clone all fields into a fresh Game instance
        let finished = Game(
            id:           game.id,
            location:     game.location,
            date:         game.date,
            completed:    game.completed,
            numberOfHoles: game.numberOfHoles,
            started:      game.started,
            dismissed:    game.dismissed,
            totalTime:    game.totalTime,
            live:         game.live,
            lastUpdated:  game.lastUpdated,
            courseID:     game.courseID,
            players:      game.players.map { player in
                Player(
                    id:       player.id,
                    userId:   player.userId,
                    name:     player.name,
                    photoURL: player.photoURL,
                    holes:    player.holes.map {
                        Hole(number: $0.number, par: 2, strokes: $0.strokes)
                    }
                )
            },
        )

        
        // Now insert this *new* object
        context.insert(finished)
        do {
            try context.save()
            print("✅ Finished game saved locally")
        } catch {
            print("❌ Failed to save finished game locally:", error)
        }
        
        authModel.userModel?.games.append(finished)
        
        objectWillChange.send()
        resetGame()
    }
}
