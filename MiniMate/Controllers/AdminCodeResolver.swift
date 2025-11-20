//
//  CourseResolver.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/4/25.
//

import SwiftUI

final class AdminCodeResolver {
    
    static let adminAndId: [String: SmallCourse] = [
        "543943": SmallCourse(id: "CREATOR", name: "Creator"),
        "329742": SmallCourse(id: "FC", name: "Fore Corners Mini Golf", tier: 2)
    ]
    
    // Tells you if there is a code that matches the one entered
    static func isAdminCodeThere(code: String?) -> Bool {
        if let code = code {
            return adminAndId.keys.contains(code)
        } else {
            return false
        }
    }
    
    // tells you number of codes
    static func numOfCodes() -> Int {
        adminAndId.keys.count
    }
    
    // gives you the code for the id
    static func getCode(id: String) -> String? {
        adminAndId.keys.first { adminAndId[$0]?.id == id }
    }
    
    // if there is a name that you enter that matches one of the them in the dictionary
    static func matchName(_ name: String) -> Bool {
        adminAndId.values.contains { course in
            course.name.lowercased().contains(name.lowercased()) == true
        }
    }

    // gets course from url and authmodel
    static func resolve(url: String, authModel: any AuthViewManager, completion: @escaping (Course?) -> Void) {
        let id = url.components(separatedBy: "/").last!
        authModel.fetchCourse(id: id) { course in
            completion(course)
        }
    }
    
    // gets course just from id
    static func resolve(id: String?, authModel: any AuthViewManager, completion: @escaping (Course?) -> Void){
        if let id = id {
            authModel.fetchCourse(id: id) { course in
                completion(course)
            }
        } else {
            completion(nil)
        }
    }
    
    // gets course from name
    static func resolve(name: String, authModel: any AuthViewManager, completion: @escaping (Course?) -> Void){
    
        let id = adminAndId.first { adminAndId[$0.key]?.name.lowercased() == name.lowercased()}?.value.id
        if let id = id {
            authModel.fetchCourse(id: id) { course in
                completion(course)
            }
        } else {
            completion(nil)
        }
    }

    // if you have the name gets you the id of the course
    static func nameToId(_ name: String) -> String? {
        adminAndId.first { adminAndId[$0.key]?.name.lowercased() == name.lowercased() }?.value.id
    }
    
    // if you have the id gets you the name of the course
    static func idToName(_ id: String) -> String? {
        adminAndId.first { adminAndId[$0.key]?.id.lowercased() == id.lowercased() }?.value.name
    }
    
    // if you have the id gets you the tier
    static func idToTier(_ id: String) -> Int? {
        adminAndId.first { adminAndId[$0.key]?.id.lowercased() == id.lowercased() }?.value.tier
    }
    
}

// small course struct
struct SmallCourse{
    var id: String
    var name: String
    var tier: Int? = nil
}

