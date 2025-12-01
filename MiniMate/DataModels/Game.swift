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
    var startTime: Date?
    var endTime: Date?
    
    var holeInOneLastHole: Bool {
        var temp = false
        for player in players {
            for hole in player.holes {
                if hole.number == 18 && hole.strokes == 1 {
                    temp = true
                }
            }
        }
        return temp
    }

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
        lhs.courseID       == rhs.courseID &&  // <-- compare courseID
        lhs.startTime      == rhs.startTime &&
        lhs.endTime      == rhs.endTime
    }

    enum CodingKeys: String, CodingKey {
        case id, location, date, completed,
             numberOfHoles, started, dismissed,
             totalTime, live, lastUpdated,
             players, courseID, editOn, startTime, endTime  // <-- added courseID
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
        players: [Player] = [],
        startTime: Date? = nil,
        endTime: Date? = nil
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
        self.startTime      = startTime
        self.endTime        = endTime
    }

    func toDTO() -> GameDTO {
        return GameDTO(
            id: id,
            location: location,
            date: date.timeIntervalSince1970,
            completed: completed,
            numberOfHoles: numberOfHoles,
            started: started,
            dismissed: dismissed,
            totalTime: totalTime,
            live: live,
            lastUpdated: lastUpdated.timeIntervalSince1970,
            courseID: courseID,  // <-- include courseID
            players: players.map { $0.toDTO() },
            startTime: startTime?.timeIntervalSince1970,
            endTime: endTime?.timeIntervalSince1970
        )
    }

    static func fromDTO(_ dto: GameDTO) -> Game {
        return Game(
            id: dto.id,
            location: dto.location,
            date: Date(timeIntervalSince1970: dto.date),
            completed: dto.completed,
            numberOfHoles: dto.numberOfHoles,
            started: dto.started,
            dismissed: dto.dismissed,
            totalTime: dto.totalTime,
            live: dto.live,
            lastUpdated: Date(timeIntervalSince1970: dto.lastUpdated),
            courseID: dto.courseID,  // <-- include courseID
            players: dto.players.map { Player.fromDTO($0) },
            startTime: Date(timeIntervalSince1970: dto.startTime ?? 0),
            endTime: Date(timeIntervalSince1970: dto.endTime ?? 0)
        )
    }
}


struct GameDTO: Codable {
    var id: String
    var location: MapItemDTO?
    var date: Double
    var completed: Bool
    var numberOfHoles: Int
    var started: Bool
    var dismissed: Bool
    var totalTime: Int
    var live: Bool
    var lastUpdated: Double
    var courseID: String? // <-- Added here
    var players: [PlayerDTO]
    var startTime: Double?
    var endTime: Double?

    enum CodingKeys: String, CodingKey {
        case id, location, date, completed,
             numberOfHoles, started, dismissed,
             totalTime, live, lastUpdated,
             courseID, // <-- Added here
             players, endTime, startTime
    }

    // Decode missing fields gracefully
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(String.self,                 forKey: .id)
        location       = try c.decodeIfPresent(MapItemDTO.self,   forKey: .location)
        date           = try c.decodeIfPresent(Double.self,         forKey: .date)          ?? 0
        completed      = try c.decodeIfPresent(Bool.self,         forKey: .completed)     ?? false
        numberOfHoles  = try c.decodeIfPresent(Int.self,          forKey: .numberOfHoles) ?? 0
        started        = try c.decodeIfPresent(Bool.self,         forKey: .started)       ?? false
        dismissed      = try c.decodeIfPresent(Bool.self,         forKey: .dismissed)     ?? false
        totalTime      = try c.decodeIfPresent(Int.self,          forKey: .totalTime)     ?? 0
        live           = try c.decodeIfPresent(Bool.self,         forKey: .live)          ?? false
        lastUpdated    = try c.decodeIfPresent(Double.self,         forKey: .lastUpdated)   ?? 0
        courseID       = try c.decodeIfPresent(String.self,       forKey: .courseID)      ?? nil // <-- Added here
        players        = try c.decodeIfPresent([PlayerDTO].self,  forKey: .players)       ?? []
        startTime    = try c.decodeIfPresent(Double.self,         forKey: .startTime)   ?? 0
        endTime    = try c.decodeIfPresent(Double.self,         forKey: .endTime)   ?? 0
    }

    // Memberwise initializer
    init(
        id: String,
        location: MapItemDTO? = nil,
        date: Double,
        completed: Bool,
        numberOfHoles: Int,
        started: Bool,
        dismissed: Bool,
        totalTime: Int,
        live: Bool,
        lastUpdated: Double,
        courseID: String?, // <-- Added here
        players: [PlayerDTO],
        startTime: Double?,
        endTime: Double?
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
        self.startTime      = startTime
        self.endTime        = endTime
    }
}

