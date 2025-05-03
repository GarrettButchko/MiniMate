//
//  Player.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/2/25.
//

// Models.swift
import Foundation
import SwiftData
import MapKit
import Contacts

// MARK: - Player

@Model
class Player: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var inGame: Bool = false
    var name: String
    var photoURL: URL?
    var totalStrokes: Int = 0
    
    @Relationship(deleteRule: .nullify)
      var game: Game?

    @Relationship(deleteRule: .cascade, inverse: \Hole.player)
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
