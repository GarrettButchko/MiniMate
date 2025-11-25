//
//  Course.swift
//  MiniMate
//

import SwiftUI

struct Course: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var logo: String?
    var colorsS: [String]
    var link: String?
    var pars: [Int]
    var adTitle: String?
    var adDescription: String?
    var adLink: String?
    var adImage: String?
    var emails: [String]?
    
    // Analytics
    var dailyCounts: [DailyCount]
    var peakAnalytics: PeakAnalytics
    var holeAnalytics: HoleAnalytics
    var roundTimeAnalytics: RoundTimeAnalytics

    // MARK: - Init
    init(
        id: String = "",
        name: String = "",
        logo: String? = nil,
        colorsS: [String] = ["red", "orange", "yellow", "green", "blue", "indigo", "purple"],
        link: String? = nil,
        pars: [Int] = [0],
        adTitle: String? = nil,
        adDescription: String? = nil,
        adLink: String? = nil,
        adImage: String? = nil,
        emails: [String]? = nil,
        dailyCounts: [DailyCount] = [],
        peakAnalytics: PeakAnalytics = PeakAnalytics(),
        holeAnalytics: HoleAnalytics = HoleAnalytics(),
        roundTimeAnalytics: RoundTimeAnalytics = RoundTimeAnalytics()
    ) {
        self.id = id
        self.name = name
        self.logo = logo
        self.colorsS = colorsS
        self.link = link
        self.pars = pars
        self.adTitle = adTitle
        self.adDescription = adDescription
        self.adLink = adLink
        self.adImage = adImage
        self.emails = emails
        self.dailyCounts = dailyCounts
        self.peakAnalytics = peakAnalytics
        self.holeAnalytics = holeAnalytics
        self.roundTimeAnalytics = roundTimeAnalytics
    }

    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.logo == rhs.logo &&
               lhs.colorsS == rhs.colorsS &&
               lhs.link == rhs.link &&
               lhs.pars == rhs.pars &&
               lhs.adTitle == rhs.adTitle &&
               lhs.adDescription == rhs.adDescription &&
               lhs.adLink == rhs.adLink &&
               lhs.adImage == rhs.adImage &&
               lhs.emails == rhs.emails
    }

    // MARK: - Computed Properties
    var numOfHoles: Int {
        pars.count
    }

    var hasPars: Bool {
        pars.contains { $0 != 2 }
    }

    var holes: [Hole] {
        (1...numOfHoles).map { index in
            Hole(number: index, par: hasPars ? pars[index - 1] : 2)
        }
    }

    var colors: [Color] {
        colorsS.compactMap { colorName in
            switch colorName.lowercased() {
            case "red": return .red
            case "orange": return .orange
            case "yellow": return .yellow
            case "green": return .green
            case "blue": return .blue
            case "indigo": return .indigo
            case "purple": return .purple
            case "pink": return .pink
            case "gray", "grey": return .gray
            case "black": return .black
            case "white": return .white
            case "cyan": return .cyan
            case "mint": return .mint
            case "teal": return .teal
            case "brown": return .brown
            default: return nil
            }
        }
    }
}

struct DailyCount: Codable, Identifiable {
    var id: String                  // e.g., "2025-11-22"
    var activeUsers: Int = 0        // number of users active that day
    var gamesPlayed: Int = 0        // optional metric
    var newPlayers: Int = 0         // optional metric
    
    init(
        id: String = "",
        activeUsers: Int = 0,
        gamesPlayed: Int = 0,
        newPlayers: Int = 0
    ) {
        self.id = id
        self.activeUsers = activeUsers
        self.gamesPlayed = gamesPlayed
        self.newPlayers = newPlayers
    }
}

struct PeakAnalytics: Codable, Identifiable {
    var id: String = "peakAnalytics"
    // single doc per course
    var hourlyCounts: [Int]           // 24 integers, index 0 = 12AM-1AM, 23 = 11PM-12AM
    var dailyCounts: [Int]            // 7 integers, index 0 = Sunday, 6 = Saturday
    
    init(hourlyCounts: [Int]? = nil, dailyCounts: [Int]? = nil) {
        self.hourlyCounts = hourlyCounts ?? Array(repeating: 0, count: 24)
        self.dailyCounts = dailyCounts ?? Array(repeating: 0, count: 7)
    }
}

struct HoleAnalytics: Codable, Identifiable {
    var id: String = "holeAnalytics"   // single doc per course
    var totalStrokesPerHole: [Int]     // e.g., [totalHole1, totalHole2, ...]
    var playsPerHole: [Int]            // e.g., [numPlaysHole1, numPlaysHole2, ...]
    
    init(numHoles: Int = 18) {
        self.totalStrokesPerHole = Array(repeating: 0, count: numHoles)
        self.playsPerHole = Array(repeating: 0, count: numHoles)
    }
    
    /// Returns the average score per hole
    func averagePerHole() -> [Double] {
        zip(totalStrokesPerHole, playsPerHole).map { total, plays in
            plays > 0 ? Double(total) / Double(plays) : 0
        }
    }
}

struct RoundTimeAnalytics: Codable, Identifiable {
    var id: String = "roundTimeAnalytics"   // single doc per course
    var totalRoundSeconds: Int = 0          // cumulative total time of all rounds
    var numberOfRounds: Int = 0             // number of rounds played
    
    /// Adds a completed round's length
    mutating func addRound(roundLengthSeconds: Int) {
        totalRoundSeconds += roundLengthSeconds
        numberOfRounds += 1
    }
    
    /// Returns the average round time in seconds
    func averageRoundTime() -> Double {
        numberOfRounds > 0 ? Double(totalRoundSeconds) / Double(numberOfRounds) : 0
    }
}


struct CourseLeaderboard: Codable, Identifiable {
    var id: String           // course ID
    var allPlayers: [PlayerDTO] = [] // current leaderboard
    
    init(id: String = "", allPlayers: [PlayerDTO] = []) {
        self.id = id
        self.allPlayers = allPlayers
    }
    
    /// Returns a sorted leaderboard by total strokes (ascending)
    var leaderBoard: [PlayerDTO] {
        allPlayers.sorted { $0.totalStrokes < $1.totalStrokes }
    }
}
