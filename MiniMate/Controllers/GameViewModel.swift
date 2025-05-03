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
    
    
    // MARK: - Public Actions
    func resetGame() {
        game = Game()
    }
    
    func setGame(_ newGame: Game) {
            objectWillChange.send()
            // Tear down any existing listener
            stopListening()
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

            // 2) Rebuild players and their holes from remote data
            for remotePlayer in newGame.players {
                initializeHoles(for: remotePlayer)
                // remotePlayer.holes already contains correct strokes
                // Append the fully initialized player
                game.players.append(remotePlayer)
            }

            // Restart updates if needed
            if onlineGame {
                listenForUpdates()
            }
        }

    
    func setOnlineGame(_ onlineGame: Bool) {
        self.onlineGame = onlineGame
    }
    
    func setCompletedGame(_ completedGame: Bool) {
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        self.game.completed = completedGame
        pushUpdate()
    }
    
    func setLocation(_ location: MapItemDTO) {
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        self.game.location = location
        pushUpdate()
    }

    func stopListening() {
      guard let ref = gameRef(), let handle = listenerHandle else { return }
      ref.removeObserver(withHandle: handle)
      listenerHandle = nil
    }

    // MARK: - Updating DataBase
    func pushUpdate() {
        guard gameRef() != nil else { return }
        objectWillChange.send() // notify before mutating
        lastUpdated = Date()
        game.lastUpdated = lastUpdated
        guard onlineGame else { return }
        authModel.addOrUpdateGame(game) { _ in }
    }

    
    private func gameRef() -> DatabaseReference? {
      guard onlineGame,
            !game.id.isEmpty,
            game.id.rangeOfCharacter(from: CharacterSet(charactersIn: ".#\\$\\[\\]]")) == nil
      else {
        return nil
      }
      return Database.database()
             .reference()
             .child("games")
             .child(game.id)
    }
    
    func listenForUpdates() {
        guard onlineGame else { return }
        guard let ref = gameRef() else {
          print("⚠️ Invalid game.id “\(game.id)” — skipping Firebase call")
          return
        }

        listenerHandle = ref.observe(.value) { [weak self] snap in
            guard let self = self,
                  snap.exists(),
                  let dto: GameDTO = try? snap.data(as: GameDTO.self)
            else { return }
            let incoming = Game.fromDTO(dto)

            // ignore echoes
            guard incoming.lastUpdated > self.game.lastUpdated else { return }

            self.objectWillChange.send()
            self.game.lastUpdated = incoming.lastUpdated

            // 1) merge top‐level fields…
            self.game.id          = incoming.id
            self.game.location          = incoming.location
            self.game.date          = incoming.date
            self.game.completed     = incoming.completed
            self.game.numberOfHoles = incoming.numberOfHoles
            self.game.started       = incoming.started
            self.game.dismissed     = incoming.dismissed
            self.game.live    = incoming.live

            // 2) build a lookup of remote players by ID
            let remoteByID = Dictionary(uniqueKeysWithValues:
                incoming.players.map { ($0.id, $0) }
            )

            // 3) update or remove existing local players
            self.game.players.removeAll { local in
                guard let remote = remoteByID[local.id] else {
                    // local player no longer in remote list → drop them
                    return true
                }
                // still present → update their fields
                local.totalStrokes = remote.totalStrokes
                local.inGame       = remote.inGame

                // merge holes
                for (hIdx, holeDTO) in remote.holes.enumerated() where hIdx < local.holes.count {
                    local.holes[hIdx].strokes = holeDTO.strokes
                }

                return false
            }

            // 4) append any brand‐new players
            for remote in incoming.players where !self.game.players.contains(where: { $0.userId == remote.id }) {
    
                initializeHoles(for: remote)
                self.game.players.append(remote)
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
            userId: generateGameCode(),
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
      // don’t add the same user twice
      guard !game.players.contains(where: { $0.userId == user.id }) else { return }

      objectWillChange.send()
      let newPlayer = Player(
        userId: user.id,
        name: user.name,
        photoURL: user.photoURL,
        totalStrokes: 0,
        inGame: true
      )
      initializeHoles(for: newPlayer)
      game.players.append(newPlayer)
      pushUpdate()
    }


    func removePlayer(userId: String) {
        objectWillChange.send()
        game.players.removeAll { $0.userId == userId }
        pushUpdate()
    }
    
    func joinGame(id: String, completion: @escaping (Bool) -> Void) {
        guard onlineGame else { return }
        authModel.fetchGame(id: id) { game in
            if let game = game, !game.dismissed, !game.started, !game.completed {
                self.setGame(game)
                self.addUser()
                self.listenForUpdates()
                completion(true)
            } else {
                completion (false)
            }
            completion(false)
        }
    }
    
    func leaveGame(userId: String) {
        guard onlineGame else { return }
        objectWillChange.send()
        stopListening()
        self.removePlayer(userId: userId)
        pushUpdate()
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
        resetGame()
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
        guard !game.dismissed else { return }
        objectWillChange.send()
        stopListening()         // tear down any existing listener
        game.dismissed = true
        pushUpdate()            // push the “dismissed” flag
        deleteFromFirebaseGamesArr()

        resetGame()             // now creates a new Game with id == ""
    }

    
    /// Deep-clone the game you just finished, persist it locally & remotely, then reset.
    func finishAndPersistGame(in context: ModelContext) {
      // 1️⃣ Tear down real-time syncing
      stopListening()

      
        let holeCount = game.players.first?.holes.count ?? 0
          print("🔍 Persisting game \(game.id) with \(holeCount) holes")

      // 3️⃣ Persist into SwiftData
      context.insert(game)
      do {
        try context.save()
        print("✅ Finished game saved locally")
          debugPrintContext(context)    // ← dump everything
      } catch {
        print("❌ Failed to save finished game locally:", error)
      }

      // 4️⃣ Push into the user’s history
      authModel.userModel?.games.append(game)
      authModel.saveUserModel(authModel.userModel!) { success in
        print(success
          ? "✅ UserModel updated with new game"
          : "❌ Failed to update UserModel")
      }

      // 5️⃣ Finally reset the live game
      objectWillChange.send()
      resetGame()
    }
    
    // MARK: - Debug
        /// A quick dump of every Game, its Players, and detailed Hole model info
        func debugPrintContext(_ context: ModelContext) {
            let allGames: [Game] = (try? context.fetch(FetchDescriptor<Game>())) ?? []
            print("🗄️ ModelContext contains \(allGames.count) games:")
            for game in allGames {
                let totalHoles = game.players.reduce(0) { $0 + $1.holes.count }
                print("– Game \(game.id) (completed: \(game.completed), date: \(game.date), totalHoles: \(totalHoles))")
                for player in game.players {
                    print("    • Player \(player.name) (id: \(player.id)) has \(player.holes.count) holes:")
                    let sortedHoles = player.holes.sorted { $0.number < $1.number }
                    for hole in sortedHoles {
                        print("      – Hole #\(hole.number) [id: \(hole.id)] par=\(hole.par), strokes=\(hole.strokes), playerId=\(hole.player?.id ?? "nil")")
                    }
                }
            }
        }
}
