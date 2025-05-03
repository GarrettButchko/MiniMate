//
//  UserModel.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/2/25.
//
import Foundation
import SwiftData
import MapKit
import Contacts

@Model
class UserModel: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var name: String
    var photoURL: URL?
    var email: String?

    @Relationship(deleteRule: .cascade, inverse: \Game.user)
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
