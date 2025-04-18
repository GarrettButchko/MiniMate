import Foundation
import SwiftData

// MARK: - UserModel

/// Represents a user and their associated games
@Model
class UserModel: Codable, Identifiable {
    
    /// Unique user identifier (should match Firebase UID)
    @Attribute(.unique) var id: String
    var name: String
    var email: String
    var password: String? = nil
    
    /// List of games played by the user (with cascade delete)
    @Relationship(deleteRule: .cascade) var games: [GameModel]

    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case id, name, email, password, games
    }

    init(id: String, name: String, email: String, password: String? = nil, games: [GameModel]) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
        self.games = games
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let email = try container.decode(String.self, forKey: .email)
        let password = try container.decodeIfPresent(String.self, forKey: .password)
        let games = try container.decode([GameModel].self, forKey: .games)
        self.init(id: id, name: name, email: email, password: password, games: games)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(password, forKey: .password)
        try container.encode(games, forKey: .games)
    }
}


// MARK: - GameModel

/// Represents a game session, including GPS location and associated holes
@Model
class GameModel: Codable {
    var name: String
    var lat: Double
    var long: Double
    var date: Date

    /// List of holes in this game (with cascade delete)
    @Relationship(deleteRule: .cascade) var holes: [HoleModel]

    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case name, lat, long, date, holes
    }

    init(name: String, lat: Double, long: Double, date: Date, holes: [HoleModel] = []) {
        self.name = name
        self.lat = lat
        self.long = long
        self.date = date
        self.holes = holes
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let lat = try container.decode(Double.self, forKey: .lat)
        let long = try container.decode(Double.self, forKey: .long)
        let date = try container.decode(Date.self, forKey: .date)
        let holes = try container.decode([HoleModel].self, forKey: .holes)
        self.init(name: name, lat: lat, long: long, date: date, holes: holes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(lat, forKey: .lat)
        try container.encode(long, forKey: .long)
        try container.encode(date, forKey: .date)
        try container.encode(holes, forKey: .holes)
    }
}

// MARK: - HoleModel

/// Represents a single hole in a game, including par and strokes taken
@Model
class HoleModel: Codable {
    var number: Int      // Hole number (1-based)
    var par: Int         // Expected strokes
    var strokes: Int     // Actual strokes (default 0)

    // MARK: - Coding

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

