import Foundation
import SwiftData

// MARK: - UserModel

/// Represents a user and their associated games
@Model
class UserModel: Identifiable, Equatable {
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
}


@Model
class UserModelEssentials: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var name: String
    var photoURL: URL?
    
    var totalStrokes: Int = 0  // <-- Added here

    @Relationship(deleteRule: .cascade)
    var holes: [HoleModel] = []

    static func == (lhs: UserModelEssentials, rhs: UserModelEssentials) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.photoURL == rhs.photoURL &&
        lhs.totalStrokes == rhs.totalStrokes &&  // <-- Include in equality
        lhs.holes == rhs.holes
    }

    enum CodingKeys: String, CodingKey {
        case id, name, photoURL, totalStrokes, holes
    }

    init(id: String, name: String, photoURL: URL? = nil, totalStrokes: Int = 0, holes: [HoleModel] = []) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
        self.totalStrokes = totalStrokes
        self.holes = holes
        
        // Make sure to set the player relationship for each hole
        for hole in self.holes {
            hole.player = self
        }
    }
}



// MARK: - GameModel

@Model
class GameModel: Equatable {
    var id: String
    var lat: Double? = nil
    var long: Double? = nil
    var date: Date
    var completed: Bool = false
    var numberOfHoles: Int = 18
    var started: Bool = false
    var dismissed: Bool = false  // <-- Added here

    @Relationship(deleteRule: .cascade)
    var holes: [HoleModel] = []

    var playerIDs: [UserModelEssentials] = []

    static func == (lhs: GameModel, rhs: GameModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.lat == rhs.lat &&
        lhs.long == rhs.long &&
        lhs.date == rhs.date &&
        lhs.completed == rhs.completed &&
        lhs.numberOfHoles == rhs.numberOfHoles &&
        lhs.started == rhs.started &&
        lhs.dismissed == rhs.dismissed &&  // <-- Include in equality
        lhs.holes == rhs.holes &&
        lhs.playerIDs == rhs.playerIDs
    }

    enum CodingKeys: String, CodingKey {
        case id, lat, long, date, completed, numberOfHoles, holes, playerIDs, started, dismissed
    }

    init(id: String,
         lat: Double? = nil,
         long: Double? = nil,
         date: Date,
         completed: Bool = false,
         numberOfHoles: Int = 18,
         started: Bool = false,
         dismissed: Bool = false,  // <-- Add here
         holes: [HoleModel] = [],
         playerIDs: [UserModelEssentials] = []) {
        self.id = id
        self.lat = lat
        self.long = long
        self.date = date
        self.completed = completed
        self.numberOfHoles = numberOfHoles
        self.started = started
        self.dismissed = dismissed  // <-- Initialize
        self.holes = holes
        self.playerIDs = playerIDs
    }
}




// MARK: - HoleModel

/// Represents a single hole in a game, including par and strokes taken
@Model
class HoleModel: Equatable {
    var number: Int      // Hole number (1-based)
    var par: Int = 2     // Expected strokes
    var strokes: Int     // Actual strokes (default 0)
    
    @Relationship(inverse: \UserModelEssentials.holes)
        var player: UserModelEssentials?

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
}

// MARK: - DTO Structs for Firebase JSON

struct UserModelDTO: Codable {
    var id: String
    var mini: UserModelEssentialsDTO
    var email: String?
    var games: [GameModelDTO]? = [] // ✅ Make optional
}

struct UserModelEssentialsDTO: Codable {
    var id: String
    var name: String
    var photoURL: URL?
    var totalStrokes: Int  // <-- Added
    var holes: [HoleModelDTO]? = []
}

struct GameModelDTO: Codable {
    var id: String
    var lat: Double?
    var long: Double?
    var date: Date
    var completed: Bool
    var numberOfHoles: Int
    var started: Bool
    var dismissed: Bool  // <-- Add here
    var holes: [HoleModelDTO]? = []
    var playerIDs: [UserModelEssentialsDTO]? = []
}


struct HoleModelDTO: Codable {
    var number: Int
    var par: Int
    var strokes: Int
}


// MARK: - Conversion Extensions

extension UserModel {
    func toDTO() -> UserModelDTO {
        return UserModelDTO(
            id: self.id,
            mini: self.mini.toDTO(),
            email: self.email,
            games: self.games.map { $0.toDTO() }
        )
    }

    static func fromDTO(_ dto: UserModelDTO) -> UserModel {
        return UserModel(
            id: dto.id,
            mini: UserModelEssentials.fromDTO(dto.mini),
            email: dto.email,
            games: (dto.games ?? []).map { GameModel.fromDTO($0) }
        )
    }
}

extension UserModelEssentials {
    func toDTO() -> UserModelEssentialsDTO {
        return UserModelEssentialsDTO(
            id: self.id,
            name: self.name,
            photoURL: self.photoURL,
            totalStrokes: self.totalStrokes,  // <-- Added
            holes: self.holes.map { $0.toDTO() }
        )
    }

    static func fromDTO(_ dto: UserModelEssentialsDTO) -> UserModelEssentials {
        return UserModelEssentials(
            id: dto.id,
            name: dto.name,
            photoURL: dto.photoURL,
            totalStrokes: dto.totalStrokes,  // <-- Added
            holes: dto.holes?.map { HoleModel.fromDTO($0) } ?? []
        )
    }
}

extension GameModel {
    func toDTO() -> GameModelDTO {
        return GameModelDTO(
            id: self.id,
            lat: self.lat,
            long: self.long,
            date: self.date,
            completed: self.completed,
            numberOfHoles: self.numberOfHoles,
            started: self.started,
            dismissed: self.dismissed,  // <-- Add here
            holes: self.holes.map { $0.toDTO() },
            playerIDs: self.playerIDs.map { $0.toDTO() }
        )
    }

    static func fromDTO(_ dto: GameModelDTO) -> GameModel {
        return GameModel(
            id: dto.id,
            lat: dto.lat,
            long: dto.long,
            date: dto.date,
            completed: dto.completed,
            numberOfHoles: dto.numberOfHoles,
            started: dto.started,
            dismissed: dto.dismissed,  // <-- Add here
            holes: dto.holes?.map { HoleModel.fromDTO($0) } ?? [],
            playerIDs: dto.playerIDs?.map { UserModelEssentials.fromDTO($0) } ?? []
        )
    }
}


extension HoleModel {
    func toDTO() -> HoleModelDTO {
        return HoleModelDTO(number: self.number, par: self.par, strokes: self.strokes)
    }

    static func fromDTO(_ dto: HoleModelDTO) -> HoleModel {
        return HoleModel(number: dto.number, par: dto.par, strokes: dto.strokes)
    }
}


