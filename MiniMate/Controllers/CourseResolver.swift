//
//  CourseResolver.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/4/25.
//

import SwiftUICore

final class CourseResolver {
    
    static let courses: [Course] = [
        Course(
            id: "FC",
            name: "Fore Corners Mini Golf",
            logo: "fore_corners",
            colors: [Color.blue, Color.red, Color.green],
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

