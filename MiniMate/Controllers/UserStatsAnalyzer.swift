//
//  UserStatsAnalyzer.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/29/25.
//


import Foundation

struct UserStatsAnalyzer {
    let user: UserModel

    // MARK: - Basic Stats

    var totalGamesPlayed: Int {
        user.games.count
    }

    var totalPlayersFaced: Int {
        Set(user.games.flatMap { $0.players.map { $0.userId } }).count
    }

    var totalStrokes: Int {
        user.games.flatMap { $0.players }.filter { $0.userId == user.id }.flatMap { $0.holes }.map { $0.strokes }.reduce(0, +)
    }

    var totalHolesPlayed: Int {
        user.games.flatMap { $0.players }.filter { $0.userId == user.id }.flatMap { $0.holes }.count
    }

    var averageStrokesPerGame: Double {
        guard totalGamesPlayed > 0 else { return 0 }
        return Double(totalStrokes) / Double(totalGamesPlayed)
    }

    var averageStrokesPerHole: Double {
        guard totalHolesPlayed > 0 else { return 0 }
        return Double(totalStrokes) / Double(totalHolesPlayed)
    }

    // MARK: - Performance Stats

    var bestGameStrokes: Int? {
        user.games.compactMap { game in
            game.players.first(where: { $0.userId == user.id })?.holes.map { $0.strokes }.reduce(0, +)
        }.min()
    }

    var worstGameStrokes: Int? {
        user.games.compactMap { game in
            game.players.first(where: { $0.userId == user.id })?.holes.map { $0.strokes }.reduce(0, +)
        }.max()
    }
    
    


    var holeInOneCount: Int {
        user.games.flatMap { $0.players }
            .filter { $0.userId == user.id }
            .flatMap { $0.holes }
            .filter { $0.strokes == 1 }
            .count
    }
    
    // MARK: - Average Holes Maps
        
        var averageHoles9: [Hole] {
            averageHolesMap(numberOfHoles: 9)
        }
        
        var averageHoles18: [Hole] {
            averageHolesMap(numberOfHoles: 18)
        }
        
        private func averageHolesMap(numberOfHoles: Int) -> [Hole] {
            var holeStrokesDict: [Int: [Int]] = [:] // hole number -> list of strokes

            // Go through all games, all players, all holes
            for game in user.games {
                if let player = game.players.first(where: { $0.userId == user.id }) {
                    for hole in player.holes {
                        guard hole.number <= numberOfHoles else { continue }
                        holeStrokesDict[hole.number, default: []].append(hole.strokes)
                    }
                }
            }

            // Map to average strokes per hole
            var averageHoles: [Hole] = []
            for holeNumber in 1...numberOfHoles {
                let strokesList = holeStrokesDict[holeNumber] ?? []
                let average = strokesList.isEmpty ? 0 : Double(strokesList.reduce(0, +)) / Double(strokesList.count)
                let roundedAverage = Double(round(100 * average) / 100) // Round to 2 decimals
                averageHoles.append(Hole(number: holeNumber, par: 2, strokes: Int(roundedAverage)))
            }

            return averageHoles
        }
    
    
    var latestGame: Game? {
        user.games.sorted(by: { $0.date > $1.date }).first
    }
    
    var winnerOfLatestGame: Player? {
        latestGame?.players.sorted(by: { $0.totalStrokes < $1.totalStrokes }).first
    }
    
    var usersScoreOfLatestGame: Int {
        latestGame?.players.first(where: {$0.userId == user.id})?.totalStrokes ?? 0
    }
    
    var usersHolesOfLatestGame: [Hole] {
        latestGame?.players.first(where: {$0.userId == user.id})?.holes ?? []
    }
    
    var hasGames: Bool {
        !(user.games.isEmpty)
    }
    
}
