import Foundation
import SwiftData
import MapKit
import Contacts


@Model
class Game: Equatable {
    @Attribute(.unique) var id: String
    var location: MapItemDTO?
    var date: Date
    var completed: Bool
    var numberOfHoles: Int
    var started: Bool
    var dismissed: Bool
    var totalTime: Int
    var live: Bool
    var lastUpdated: Date
    var courseID: String?  // <-- Added courseID
    
    @Relationship(deleteRule: .nullify)
    var user: UserModel?

    @Relationship(deleteRule: .cascade, inverse: \Player.game)
    var players: [Player] = []

    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id             == rhs.id &&
        lhs.location       == rhs.location &&
        lhs.date           == rhs.date &&
        lhs.completed      == rhs.completed &&
        lhs.numberOfHoles  == rhs.numberOfHoles &&
        lhs.started        == rhs.started &&
        lhs.dismissed      == rhs.dismissed &&
        lhs.totalTime      == rhs.totalTime &&
        lhs.live           == rhs.live &&
        lhs.lastUpdated    == rhs.lastUpdated &&
        lhs.players        == rhs.players &&
        lhs.courseID       == rhs.courseID  // <-- compare courseID
    }

    enum CodingKeys: String, CodingKey {
        case id, location, date, completed,
             numberOfHoles, started, dismissed,
             totalTime, live, lastUpdated,
             players, courseID  // <-- added courseID
    }

    init(
        id: String = "",
        location: MapItemDTO? = nil,
        date: Date = Date(),
        completed: Bool = false,
        numberOfHoles: Int = 18,
        started: Bool = false,
        dismissed: Bool = false,
        totalTime: Int = 0,
        live: Bool = false,
        lastUpdated: Date = Date(),
        courseID: String? = nil,  // <-- added courseID to init
        players: [Player] = []
    ) {
        self.id             = id
        self.location       = location
        self.date           = date
        self.completed      = completed
        self.numberOfHoles  = numberOfHoles
        self.started        = started
        self.dismissed      = dismissed
        self.totalTime      = totalTime
        self.live           = live
        self.lastUpdated    = lastUpdated
        self.courseID       = courseID  // <-- assign courseID
        self.players        = players
    }

    func toDTO() -> GameDTO {
        return GameDTO(
            id: id,
            location: location,
            date: date,
            completed: completed,
            numberOfHoles: numberOfHoles,
            started: started,
            dismissed: dismissed,
            totalTime: totalTime,
            live: live,
            lastUpdated: lastUpdated,
            courseID: courseID,  // <-- include courseID
            players: players.map { $0.toDTO() }
        )
    }

    static func fromDTO(_ dto: GameDTO) -> Game {
        return Game(
            id: dto.id,
            location: dto.location,
            date: dto.date,
            completed: dto.completed,
            numberOfHoles: dto.numberOfHoles,
            started: dto.started,
            dismissed: dto.dismissed,
            totalTime: dto.totalTime,
            live: dto.live,
            lastUpdated: dto.lastUpdated,
            courseID: dto.courseID,  // <-- include courseID
            players: dto.players.map { Player.fromDTO($0) }
        )
    }
}


struct GameDTO: Codable {
    var id: String
    var location: MapItemDTO?
    var date: Date
    var completed: Bool
    var numberOfHoles: Int
    var started: Bool
    var dismissed: Bool
    var totalTime: Int
    var live: Bool
    var lastUpdated: Date
    var courseID: String? // <-- Added here
    var players: [PlayerDTO]

    enum CodingKeys: String, CodingKey {
        case id, location, date, completed,
             numberOfHoles, started, dismissed,
             totalTime, live, lastUpdated,
             courseID, // <-- Added here
             players
    }

    // Decode missing fields gracefully
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(String.self,                 forKey: .id)
        location       = try c.decodeIfPresent(MapItemDTO.self,   forKey: .location)
        date           = try c.decodeIfPresent(Date.self,         forKey: .date)          ?? Date()
        completed      = try c.decodeIfPresent(Bool.self,         forKey: .completed)     ?? false
        numberOfHoles  = try c.decodeIfPresent(Int.self,          forKey: .numberOfHoles) ?? 0
        started        = try c.decodeIfPresent(Bool.self,         forKey: .started)       ?? false
        dismissed      = try c.decodeIfPresent(Bool.self,         forKey: .dismissed)     ?? false
        totalTime      = try c.decodeIfPresent(Int.self,          forKey: .totalTime)     ?? 0
        live           = try c.decodeIfPresent(Bool.self,         forKey: .live)          ?? false
        lastUpdated    = try c.decodeIfPresent(Date.self,         forKey: .lastUpdated)   ?? Date()
        courseID       = try c.decodeIfPresent(String.self,       forKey: .courseID)      ?? nil // <-- Added here
        players        = try c.decodeIfPresent([PlayerDTO].self,  forKey: .players)       ?? []
    }

    // Memberwise initializer
    init(
        id: String,
        location: MapItemDTO? = nil,
        date: Date,
        completed: Bool,
        numberOfHoles: Int,
        started: Bool,
        dismissed: Bool,
        totalTime: Int,
        live: Bool,
        lastUpdated: Date,
        courseID: String?, // <-- Added here
        players: [PlayerDTO]
    ) {
        self.id             = id
        self.location       = location
        self.date           = date
        self.completed      = completed
        self.numberOfHoles  = numberOfHoles
        self.started        = started
        self.dismissed      = dismissed
        self.totalTime      = totalTime
        self.live           = live
        self.lastUpdated    = lastUpdated
        self.courseID       = courseID // <-- Added here
        self.players        = players
    }
}

