//
//  Course.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/1/25.
//

import SwiftUI

class Course: Identifiable {
    var id: String
    var name: String?
    var logo: String?
    var colors: [Color]
    var link: String?
    var pars: [Int]
    var gameID: String?

    // MARK: - Init

    init(
        id: String = UUID().uuidString,
        name: String? = nil,
        logo: String? = nil,
        colors: [Color] = [.red, .orange, .yellow, .green, .blue, .indigo, .purple],
        link: String? = nil,
        pars: [Int] = [],
        gameID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.logo = logo
        self.colors = colors
        self.link = link
        self.pars = pars
        self.gameID = gameID
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
}

