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
    var adminType: String? = nil
    var isPro: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Game.user)
    var games: [Game] = []

    enum CodingKeys: String, CodingKey {
        case id, name, photoURL, email, adminType, isPro, games
    }

    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.photoURL == rhs.photoURL &&
        lhs.email == rhs.email &&
        lhs.adminType == rhs.adminType &&
        lhs.isPro == rhs.isPro &&
        lhs.games == rhs.games
    }

    init(
        id: String,
        name: String,
        photoURL: URL? = nil,
        email: String? = nil,
        adminType: String? = nil,
        isPro: Bool = false,
        games: [Game] = []
    ) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
        self.email = email
        self.adminType = adminType
        self.isPro = isPro
        self.games = games
    }

    func toDTO() -> UserDTO {
        return UserDTO(
            id: id,
            name: name,
            photoURL: photoURL,
            email: email,
            adminType: adminType,
            isPro: isPro,
            games: games.map { $0.toDTO() }
        )
    }

    static func fromDTO(_ dto: UserDTO) -> UserModel {
        return UserModel(
            id: dto.id,
            name: dto.name,
            photoURL: dto.photoURL,
            email: dto.email,
            adminType: dto.adminType,
            isPro: dto.isPro,
            games: dto.games.map { Game.fromDTO($0) }
        )
    }
}

struct UserDTO: Codable {
    var id: String
    var name: String
    var photoURL: URL?
    var email: String?
    var adminType: String?
    var isPro: Bool
    var games: [GameDTO]
}
