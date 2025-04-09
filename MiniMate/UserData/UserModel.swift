import Foundation
import SwiftData

@Model
class UserModel: Codable {
    var name: String
    var email: String
    var password: String
    @Relationship(deleteRule: .cascade)
    var games: [GameModel]?

    enum CodingKeys: String, CodingKey {
        case name, email, password, games
    }

    init(name: String, email: String, password: String, games: [GameModel] = []) {
        self.name = name
        self.email = email
        self.password = password
        self.games = games
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let email = try container.decode(String.self, forKey: .email)
        let password = try container.decode(String.self, forKey: .password)
        let games = try container.decodeIfPresent([GameModel].self, forKey: .games) ?? []
        self.init(name: name, email: email, password: password, games: games)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
        try container.encodeIfPresent(games, forKey: .games)
    }
}

@Model
class GameModel: Codable {
    var name: String
    var lat: Double
    var long: Double
    var date: Date
    @Relationship(deleteRule: .cascade)
    var holes: [HoleModel]

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

@Model
class HoleModel: Codable {
    var number: Int
    var par: Int
    var strokes: Int?

    enum CodingKeys: String, CodingKey {
        case number, par, strokes
    }

    init(number: Int, par: Int, strokes: Int? = nil) {
        self.number = number
        self.par = par
        self.strokes = strokes
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let number = try container.decode(Int.self, forKey: .number)
        let par = try container.decode(Int.self, forKey: .par)
        let strokes = try container.decodeIfPresent(Int.self, forKey: .strokes)
        self.init(number: number, par: par, strokes: strokes)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(number, forKey: .number)
        try container.encode(par, forKey: .par)
        try container.encodeIfPresent(strokes, forKey: .strokes)
    }
}
