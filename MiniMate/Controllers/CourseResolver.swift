//
//  CourseResolver.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/4/25.
//

import SwiftUICore

final class CourseResolver {
    
    static let courses: [Course] = [
        //Course(
        //    id: "S",
        //    name: "Sweeties Candy Company",
        //    logo: "sweeties",
        //    colors: [Color.red, Color.green, Color.yellow],
        //    link: "https://www.sweetiescandy.com/",
        //    pars: [2, 3, 5, 3, 2, 3, 4, 3, 2, 2, 3, 4, 3, 4, 2, 3, 2, 5, 7]
        //),
        Course(
            id: "FC",
            name: "Fore Corners Mini Golf",
            logo: "fore_corners.png",
            colors: [Color.blue, Color.red],
            link: "https://www.forecornersminiaturegolf.com/",
            pars: [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 3, 3, 2]
        )
    ]
    
    static func matchName(_ name: String) -> Bool {
        courses.contains { course in
            course.name?.lowercased().contains(name.lowercased()) == true
        }
    }
    
    static func nameToId(_ name: String) -> String? {
        courses.first { $0.name?.lowercased() == name.lowercased() }?.id
    }

    static func resolve(url: String?) -> Course? {
        guard let id = url?.components(separatedBy: "/").last else {
            return nil
        }
        return resolve(id: id)
    }
    
    static func resolve(id: String?) -> Course? {
        return courses.first { $0.id == id }
    }
    
    static func resolve(name: String?) -> Course? {
        return courses.first { $0.name?.lowercased() == name?.lowercased() }
    }
}

