//
//  Course.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/1/25.
//

import SwiftUICore
import SwiftData


struct Course: Identifiable {
    var id: String
    var name: String?
    var logo: String?
    var colors: [Color] = [.red, .orange, .yellow, .green, .blue, .indigo, .purple]
    var link: String?
    var pars: [Int]

    var numOfHoles: Int {
        pars.count
    }

    var hasPars: Bool {
        pars.contains(where: { $0 != 2 })
    }

    var holes: [Hole] {
        (1...numOfHoles).map { index in
            Hole(number: index, par: hasPars ? pars[index - 1] : 2)
        }
    }
}
