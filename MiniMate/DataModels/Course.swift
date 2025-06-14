//
//  Course.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/1/25.
//

import SwiftUI

struct Course: Codable, Identifiable, Equatable{
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
    var allPlayers: [PlayerDTO]?
    var emails: [String]?
    
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
        allPlayers: [PlayerDTO]? = nil,
        emails: [String]? = nil
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
        self.allPlayers = allPlayers
        self.emails = emails
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
               lhs.allPlayers == rhs.allPlayers &&
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
            default:
                return nil // Unknown color string
            }
        }
    }
    
    var leaderBoard: [PlayerDTO]? {
        allPlayers?.sorted { $0.totalStrokes < $1.totalStrokes }
    }
}

