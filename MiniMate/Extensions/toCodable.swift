//
//  toCodable.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/7/25.
//

extension UserModel {
    func toCodable() -> CodableUserModel {
        CodableUserModel(
            name: name,
            email: email,
            password: password,
            games: games.map { $0.toCodable() }
        )
    }
    
    static func fromCodable(_ codable: CodableUserModel) -> UserModel {
        let games = codable.games.map { GameModel.fromCodable($0) }
        return UserModel(name: codable.name, email: codable.email, password: codable.password, games: games)
    }
}

extension GameModel {
    func toCodable() -> CodableGameModel {
        CodableGameModel(
            name: name,
            lat: lat,
            long: long,
            date: date,
            holes: holes.map { $0.toCodable() }
        )
    }

    static func fromCodable(_ codable: CodableGameModel) -> GameModel {
        let holes = codable.holes.map { HoleModel.fromCodable($0) }
        return GameModel(name: codable.name, lat: codable.lat, long: codable.long, date: codable.date, holes: holes)
    }
}

extension HoleModel {
    func toCodable() -> CodableHoleModel {
        CodableHoleModel(number: number, par: par, strokes: strokes)
    }

    static func fromCodable(_ codable: CodableHoleModel) -> HoleModel {
        HoleModel(number: codable.number, par: codable.par, strokes: codable.strokes)
    }
}
