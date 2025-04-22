import Foundation
import SwiftData

// MARK: - UserModel

/// Represents a user and their associated games
@Model
class UserModel: Codable, Identifiable, Equatable {
    @Attribute(.unique) var id: String
    
    var mini: UserModelEssentials
    var email: String?

    @Relationship(deleteRule: .cascade)
    var games: [GameModel] = []

    enum CodingKeys: String, CodingKey {
        case id, mini, email, games
    }
    
    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.mini == rhs.mini &&
        lhs.email == rhs.email &&
        lhs.games == rhs.games
    }

    init(id: String, mini: UserModelEssentials, email: String? = nil, games: [GameModel]) {
        self.id = id                    // <- store the Firebase UID here
        self.mini = mini
        self.email = email
        self.games = games
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let mini = try container.decode(UserModelEssentials.self, forKey: .mini)
        let email = try container.decodeIfPresent(String.self, forKey: .email)
        let games = try container.decode([GameModel].self, forKey: .games)
        self.init(id: id, mini: mini, email: email, games: games)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(mini, forKey: .mini)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encode(games, forKey: .games)
    }
}


@Model
class UserModelEssentials: Codable, Identifiable, Equatable {

    /// Unique user identifier (should match Firebase UID)
    @Attribute(.unique) var id: String
    var name: String
    var photoURL: URL?

    // MARK: - Coding
    
    static func == (lhs: UserModelEssentials, rhs: UserModelEssentials) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.photoURL == rhs.photoURL
    }

    enum CodingKeys: String, CodingKey {
        case id, name, photoURL
    }

    init(id: String, name: String, photoURL: URL? = nil) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let photoURL = try container.decodeIfPresent(URL.self, forKey: .photoURL)
        self.init(id: id, name: name, photoURL: photoURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(photoURL, forKey: .photoURL)
    }
}


// MARK: - GameModel

@Model
class GameModel: Codable, Equatable {
    var id: String
    var lat: Double? = nil
    var long: Double? = nil
    var date: Date
    var completed: Bool = false
    var numberOfHoles: Int = 18
    var started: Bool = false

    /// List of holes in this game (with cascade delete)
    @Relationship(deleteRule: .cascade)
    var holes: [HoleModel] = []

    /// List of user IDs for players (flat data, avoids recursion)
    var playerIDs: [UserModelEssentials] = []

    // MARK: - Coding
    
    static func == (lhs: GameModel, rhs: GameModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.lat == rhs.lat &&
        lhs.long == rhs.long &&
        lhs.date == rhs.date &&
        lhs.completed == rhs.completed &&
        lhs.numberOfHoles == rhs.numberOfHoles &&
        lhs.started == rhs.started &&
        lhs.holes == rhs.holes &&
        lhs.playerIDs == rhs.playerIDs
    }

    enum CodingKeys: String, CodingKey {
        case id, lat, long, date, completed, numberOfHoles, holes, playerIDs, started
    }


    init(id: String,
         lat: Double? = nil,
         long: Double? = nil,
         date: Date,
         completed: Bool = false,
         numberOfHoles: Int = 18,
         started: Bool = false,
         holes: [HoleModel] = [],
         playerIDs: [UserModelEssentials] = []) {
        self.id = id
        self.lat = lat
        self.long = long
        self.date = date
        self.completed = completed
        self.numberOfHoles = numberOfHoles
        self.started = started
        self.holes = holes
        self.playerIDs = playerIDs
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let lat = try container.decodeIfPresent(Double.self, forKey: .lat)
        let long = try container.decodeIfPresent(Double.self, forKey: .long)
        let date = try container.decode(Date.self, forKey: .date)
        let completed = try container.decode(Bool.self, forKey: .completed)
        let numberOfHoles = try container.decode(Int.self, forKey: .numberOfHoles)
        let started = try container.decode(Bool.self, forKey: .started)
        let holes = try container.decode([HoleModel].self, forKey: .holes)
        let playerIDs = try container.decode([UserModelEssentials].self, forKey: .playerIDs)

        self.init(id: id, lat: lat, long: long, date: date, completed: completed, numberOfHoles: numberOfHoles, started: started, holes: holes, playerIDs: playerIDs)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(lat, forKey: .lat)
        try container.encodeIfPresent(long, forKey: .long)
        try container.encode(date, forKey: .date)
        try container.encode(completed, forKey: .completed)
        try container.encode(numberOfHoles, forKey: .numberOfHoles)
        try container.encode(started, forKey: .started)
        try container.encodeIfPresent(holes, forKey: .holes)
        try container.encode(playerIDs, forKey: .playerIDs)
    }
}



// MARK: - HoleModel

/// Represents a single hole in a game, including par and strokes taken
@Model
class HoleModel: Codable, Equatable {
    var number: Int      // Hole number (1-based)
    var par: Int = 2     // Expected strokes
    var strokes: Int     // Actual strokes (default 0)

    // MARK: - Coding
    static func == (lhs: HoleModel, rhs: HoleModel) -> Bool {
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

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let number = try container.decode(Int.self, forKey: .number)
        let par = try container.decode(Int.self, forKey: .par)
        let strokes = try container.decodeIfPresent(Int.self, forKey: .strokes) ?? 0
        self.init(number: number, par: par, strokes: strokes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(number, forKey: .number)
        try container.encode(par, forKey: .par)
        try container.encode(strokes, forKey: .strokes)
    }
}

