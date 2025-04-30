// Models.swift
import Foundation
import SwiftData

// MARK: - UserModel

@Model
class UserModel: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var name: String
    var photoURL: URL?
    var email: String?

    @Relationship(deleteRule: .cascade)
    var games: [Game] = []

    enum CodingKeys: String, CodingKey {
        case id, name, photoURL, email, games
    }

    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.photoURL == rhs.photoURL &&
        lhs.email == rhs.email &&
        lhs.games == rhs.games
    }

    init(id: String, name: String, photoURL: URL? = nil, email: String? = nil, games: [Game] = []) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
        self.email = email
        self.games = games
    }

    func toDTO() -> UserDTO {
        return UserDTO(
            id: id,
            name: name,
            photoURL: photoURL,
            email: email,
            games: games.map { $0.toDTO() }
        )
    }

    static func fromDTO(_ dto: UserDTO) -> UserModel {
        return UserModel(
            id: dto.id,
            name: dto.name,
            photoURL: dto.photoURL,
            email: dto.email,
            games: dto.games.map { Game.fromDTO($0) }
        )
    }
}

struct UserDTO: Codable {
    var id: String
    var name: String
    var photoURL: URL?
    var email: String?
    var games: [GameDTO]
}

// MARK: - Player

@Model
class Player: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var inGame: Bool = false
    var name: String
    var photoURL: URL?
    var totalStrokes: Int = 0

    @Relationship(deleteRule: .cascade)
    var holes: [Hole] = []

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.photoURL == rhs.photoURL &&
        lhs.totalStrokes == rhs.totalStrokes &&
        lhs.inGame == rhs.inGame &&
        lhs.holes == rhs.holes
    }

    enum CodingKeys: String, CodingKey {
        case id, name, photoURL, totalStrokes, inGame, holes
    }

    init(id: String, name: String, photoURL: URL? = nil, totalStrokes: Int = 0, inGame: Bool = false, holes: [Hole] = []) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
        self.totalStrokes = totalStrokes
        self.inGame = inGame
        self.holes = holes

        for hole in self.holes {
            hole.player = self
        }
    }

    func toDTO() -> PlayerDTO {
        return PlayerDTO(
            id: id,
            name: name,
            photoURL: photoURL,
            totalStrokes: totalStrokes,
            inGame: inGame,
            holes: holes.map { $0.toDTO() }
        )
    }

    static func fromDTO(_ dto: PlayerDTO) -> Player {
        return Player(
            id: dto.id,
            name: dto.name,
            photoURL: dto.photoURL,
            totalStrokes: dto.totalStrokes,
            inGame: dto.inGame,
            holes: dto.holes.map { Hole.fromDTO($0) }
        )
    }
}

struct PlayerDTO: Codable {
    var id: String
    var name: String
    var photoURL: URL?
    var totalStrokes: Int
    var inGame: Bool
    var holes: [HoleDTO]
}

// MARK: - Game

@Model
class Game: Equatable {
    var id: String
    var lat: Double?
    var long: Double?
    var date: Date
    var completed: Bool
    var numberOfHoles: Int
    var started: Bool
    var dismissed: Bool
    var totalTime: Int
    var live: Bool
    var lastUpdated: Date

    @Relationship(deleteRule: .cascade)
    var holes: [Hole] = []

    @Relationship(deleteRule: .cascade)
    var players: [Player] = []

    // MARK: - Equatable

    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id             == rhs.id &&
        lhs.lat            == rhs.lat &&
        lhs.long           == rhs.long &&
        lhs.date           == rhs.date &&
        lhs.completed      == rhs.completed &&
        lhs.numberOfHoles  == rhs.numberOfHoles &&
        lhs.started        == rhs.started &&
        lhs.dismissed      == rhs.dismissed &&
        lhs.totalTime      == rhs.totalTime &&
        lhs.live           == rhs.live &&
        lhs.lastUpdated    == rhs.lastUpdated &&
        lhs.holes          == rhs.holes &&
        lhs.players        == rhs.players
    }

    // MARK: - Persistence Keys

    enum CodingKeys: String, CodingKey {
        case id, lat, long, date, completed,
             numberOfHoles, started, dismissed,
             totalTime, live, lastUpdated,
             holes, players
    }

    // MARK: - Init

    init(
      id: String,
      lat: Double? = nil,
      long: Double? = nil,
      date: Date,
      completed: Bool = false,
      numberOfHoles: Int = 18,
      started: Bool = false,
      dismissed: Bool = false,
      totalTime: Int = 0,
      live: Bool = false,
      lastUpdated: Date = Date(),
      holes: [Hole] = [],
      players: [Player] = []
    ) {
      self.id             = id
      self.lat            = lat
      self.long           = long
      self.date           = date
      self.completed      = completed
      self.numberOfHoles  = numberOfHoles
      self.started        = started
      self.dismissed      = dismissed
      self.totalTime      = totalTime
      self.live           = live
      self.lastUpdated    = lastUpdated
      self.holes          = holes
      self.players        = players
    }

    // MARK: - DTO Conversion

    func toDTO() -> GameDTO {
      return GameDTO(
        id: id,
        lat: lat,
        long: long,
        date: date,
        completed: completed,
        numberOfHoles: numberOfHoles,
        started: started,
        dismissed: dismissed,
        totalTime: totalTime,
        live: live,
        lastUpdated: lastUpdated,
        holes: holes.map { $0.toDTO() },
        players: players.map { $0.toDTO() }
      )
    }

    static func fromDTO(_ dto: GameDTO) -> Game {
      return Game(
        id: dto.id,
        lat: dto.lat,
        long: dto.long,
        date: dto.date,
        completed: dto.completed,
        numberOfHoles: dto.numberOfHoles,
        started: dto.started,
        dismissed: dto.dismissed,
        totalTime: dto.totalTime,
        live: dto.live,
        lastUpdated: dto.lastUpdated,
        holes: dto.holes.map { Hole.fromDTO($0) },
        players: dto.players.map { Player.fromDTO($0) }
      )
    }
}

struct GameDTO: Codable {
  var id: String
  var lat: Double?
  var long: Double?
  var date: Date
  var completed: Bool
  var numberOfHoles: Int
  var started: Bool
  var dismissed: Bool
  var totalTime: Int
  var live: Bool
  var lastUpdated: Date
  var holes: [HoleDTO]
  var players: [PlayerDTO]

  enum CodingKeys: String, CodingKey {
    case id, lat, long, date, completed,
         numberOfHoles, started, dismissed,
         totalTime, live, lastUpdated,
         holes, players
  }

  // decode missing fields gracefully
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id             = try c.decode(String.self,     forKey: .id)
    lat            = try c.decodeIfPresent(Double.self, forKey: .lat)
    long           = try c.decodeIfPresent(Double.self, forKey: .long)
    date           = try c.decodeIfPresent(Date.self,   forKey: .date) ?? Date()
    completed      = try c.decodeIfPresent(Bool.self,   forKey: .completed) ?? false
    numberOfHoles  = try c.decodeIfPresent(Int.self,    forKey: .numberOfHoles) ?? 18
    started        = try c.decodeIfPresent(Bool.self,   forKey: .started) ?? false
    dismissed      = try c.decodeIfPresent(Bool.self,   forKey: .dismissed) ?? false
    totalTime      = try c.decodeIfPresent(Int.self,    forKey: .totalTime) ?? 0
    live           = try c.decodeIfPresent(Bool.self,   forKey: .live) ?? false
    lastUpdated    = try c.decodeIfPresent(Date.self,   forKey: .lastUpdated) ?? Date()
    holes          = try c.decodeIfPresent([HoleDTO].self,   forKey: .holes)   ?? []
    players        = try c.decodeIfPresent([PlayerDTO].self, forKey: .players) ?? []
  }

  // memberwise initializer
  init(
    id: String,
    lat: Double?,
    long: Double?,
    date: Date,
    completed: Bool,
    numberOfHoles: Int,
    started: Bool,
    dismissed: Bool,
    totalTime: Int,
    live: Bool,
    lastUpdated: Date,
    holes: [HoleDTO],
    players: [PlayerDTO]
  ) {
    self.id             = id
    self.lat            = lat
    self.long           = long
    self.date           = date
    self.completed      = completed
    self.numberOfHoles  = numberOfHoles
    self.started        = started
    self.dismissed      = dismissed
    self.totalTime      = totalTime
    self.live           = live
    self.lastUpdated    = lastUpdated
    self.holes          = holes
    self.players        = players
  }
}

// MARK: - Hole

@Model
class Hole: Equatable {
    var number: Int
    var par: Int = 2
    var strokes: Int

    @Relationship(inverse: \Player.holes)
    var player: Player?

    static func == (lhs: Hole, rhs: Hole) -> Bool {
        lhs.number == rhs.number &&
        lhs.par == rhs.par &&
        lhs.strokes == rhs.strokes
    }

    enum CodingKeys: String, CodingKey {
        case number, par, strokes
    }

    init(number: Int, par: Int, strokes: Int = 0) {
        self.number = number
        self.par = par
        self.strokes = strokes
    }

    func toDTO() -> HoleDTO {
        return HoleDTO(
            number: number,
            par: par,
            strokes: strokes
        )
    }

    static func fromDTO(_ dto: HoleDTO) -> Hole {
        return Hole(
            number: dto.number,
            par: dto.par,
            strokes: dto.strokes
        )
    }
}

struct HoleDTO: Codable {
    var number: Int
    var par: Int
    var strokes: Int
}
