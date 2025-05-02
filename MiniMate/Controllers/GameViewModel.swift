//
//  GameViewModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/1/25.
//


import Foundation
import SwiftUI
import FirebaseDatabase
import MapKit
import Combine
import SwiftData

@dynamicMemberLookup
final class GameViewModel: ObservableObject {
    // MARK: - Published Game State
    
    @Published private var game: Game

    // MARK: - Dependencies & Config
    var onlineGame: Bool
    private var authModel: AuthViewModel
    private var listenerHandle: DatabaseHandle?
    private var lastUpdated: Date = Date()

    // MARK: - Initialization
    init(game: Game,
         authModel: AuthViewModel,
         onlineGame: Bool = true)
    {
        self.game = game
        self.authModel = authModel
        self.onlineGame = onlineGame
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
                self.pushUpdate()
            }
        )
    }

    /// Expose full model if needed
    // MARK: Alter Game
    var gameValue: Game { game }
    
    func resetGame() {
        objectWillChange.send()
        game = Game(id: "", date: Date(), completed: false, numberOfHoles: 18, started: false, dismissed: false, live: false, lastUpdated: Date(), holes: [], players: [])
    }
    
    // MARK: - Public Actions
    func setGame(_ newGame: Game) {
        objectWillChange.send()
        // Tear down any existing listener
        stopListening()
        // Assign new game and reset timestamp
        game = newGame
        lastUpdated = newGame.lastUpdated
        // Restart if needed
        if onlineGame {
            listenForUpdates()
        }
    }

    
    func setOnlineGame(_ onlineGame: Bool) {
        self.onlineGame = onlineGame
    }

    func stopListening() {
        if let handle = listenerHandle {
            Database.database().reference()
                .child("games")
                .child(game.id)
                .removeObserver(withHandle: handle)
        }
    }

    // MARK: - Updating DataBase
    func pushUpdate() {
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        game.lastUpdated = lastUpdated
        guard onlineGame else { return }
        authModel.addOrUpdateGame(game) { _ in }
    }

    
    func listenForUpdates() {
      guard onlineGame else { return }
      let ref = Database.database().reference()
                     .child("games")
                     .child(game.id)

      listenerHandle = ref.observe(.value) { [weak self] snap in
        guard let self = self,
              snap.exists(),
              let dto: GameDTO = try? snap.data(as: GameDTO.self)
        else { return }
        let incoming = Game.fromDTO(dto)

        // ignore your own echoes
        guard incoming.lastUpdated > self.game.lastUpdated else { return }

        // tell SwiftUI we’re about to mutate
        self.objectWillChange.send()
        self.game.lastUpdated = incoming.lastUpdated

        // 1) merge top-level fields
        self.game.date          = incoming.date
        self.game.completed     = incoming.completed
        self.game.numberOfHoles = incoming.numberOfHoles
        self.game.started       = incoming.started
        self.game.dismissed     = incoming.dismissed
        self.game.totalTime     = incoming.totalTime

        // 2) merge each player’s total and their holes’ strokes
        for (pi, remotePlayer) in incoming.players.enumerated() {
          guard pi < self.game.players.count else {
            // new player joined mid-game
            self.initializeHoles(for: remotePlayer)
            self.game.players.append(remotePlayer)
            continue
          }
          let localPlayer = self.game.players[pi]
          localPlayer.totalStrokes = remotePlayer.totalStrokes
          localPlayer.inGame       = remotePlayer.inGame

          for (hi, remoteHole) in remotePlayer.holes.enumerated() {
            guard hi < localPlayer.holes.count else { break }
            localPlayer.holes[hi].strokes = remoteHole.strokes
          }
        }
      }
    }

    
    func deleteFromFirebaseGamesArr(){
        guard onlineGame else { return }
        authModel.deleteGame(id: game.id) { result in
            if result {
                print("Deleted Game id: " + self.game.id + " From Firebase")
            }
        }
    }
    
    func saveToUser(){
        guard authModel.userModel != nil else { return }
        authModel.userModel!.games.append(game)
        if onlineGame {
            authModel.saveUserModel(authModel.userModel!) { result in
                if result {
                    print("Saved User to Firebase")
                } else {
                    print("Failed to save User to Firebase")
                }
            }
        }
    }

    // MARK: - Helpers
    private func initializeHoles(for player: Player) {
        guard player.holes.count != game.numberOfHoles else { return }
        player.holes = (0..<game.numberOfHoles).map {
            let hole = Hole(number: $0 + 1, par: 2)
            hole.player = player
            return hole
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
            id: generateGameCode(),
            name: name,
            photoURL: nil,
            totalStrokes: 0,
            inGame: true
        )
        initializeHoles(for: newPlayer)
        game.players.append(newPlayer)
        pushUpdate()
    }

    func addUser() {
        guard let user = authModel.userModel else { return }
        objectWillChange.send()
        let newPlayer = Player(
            id: user.id,
            name: user.name,
            photoURL: user.photoURL,
            totalStrokes: 0,
            inGame: true
        )
        initializeHoles(for: newPlayer)
        game.players.append(newPlayer)
        pushUpdate()
    }

    func removePlayer(id: String) {
        objectWillChange.send()
        game.players.removeAll { $0.id == id }
        pushUpdate()
    }
    
    func joinGame(id: String) {
        guard onlineGame else { return }
        authModel.fetchGame(id: id) { game in
            if let game = game, !game.dismissed, !game.started, !game.completed {
                self.setGame(game)
                self.addUser()
                self.listenForUpdates()
            }
        }
    }
    
    func leaveGame(userId: String) {
        guard onlineGame else { return }
        stopListening()
        self.removePlayer(id: userId)
        resetGame()
    }
    
    // MARK: Game State
    func startHostedGame(online: Bool, startingLoc: MKMapItem?) {
        createGame(online: online, startingLoc: startingLoc)
        listenForUpdates()
    }
    
    // MARK: Game State
    func stopHostedGame() {
        dismissGame()
    }
    
    func createGame(online: Bool ,startingLoc: MKMapItem?) {
        guard !game.live else { return }
        objectWillChange.send()
        game.live = true
        onlineGame = online
        game.id = generateGameCode()
        addUser()
        pushUpdate()
        listenForUpdates()
    }
    
    func startGame() {
        guard !game.started else { return }
        objectWillChange.send()
        game.started = true
        pushUpdate()
    }
    
    // MARK: Game State
    func dismissGame() {
        stopListening()
        guard !game.dismissed else { return }
        objectWillChange.send()
        stopListening()
        game.dismissed = true
        pushUpdate()
        deleteFromFirebaseGamesArr()
        resetGame()
    }
    
    func completeGame() {
        guard !game.completed else { return }
        objectWillChange.send()
        stopListening()
        game.completed = true
        pushUpdate()
        saveToUser()
        resetGame()
    }
}
