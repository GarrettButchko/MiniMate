//
//  CourseResolver.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/4/25.
//

import SwiftUI

// small course struct
struct SmallCourse{
    var id: String
    var name: String
    var tier: Int? = nil
}

final class AdminCodeResolver {
    
    private let courseRepo = CourseRepository()
    
    let adminAndId: [String: SmallCourse] = [
        "543943": SmallCourse(id: "CREATOR", name: "Creator"),
        "329742": SmallCourse(id: "FC", name: "Fore Corners Mini Golf", tier: 2)
    ]
    
    // MARK: - Course resolving
    func resolve(id: String, completion: @escaping (Course?) -> Void) {
        courseRepo.fetchCourse(id: id, completion: completion)
    }
    
    func resolve(name: String, completion: @escaping (Course?) -> Void) {
        guard let id = adminAndId.first(where: { $0.value.name.lowercased() == name.lowercased() })?.value.id else {
            completion(nil)
            return
        }
        resolve(id: id, completion: completion)
    }
    
    func resolve(url: String, completion: @escaping (Course?) -> Void) {
        let id = url.components(separatedBy: "/").last!
        resolve(id: id, completion: completion)
    }
    
    // MARK: - Admin code lookups
    func isAdminCodeThere(code: String?) -> Bool {
        guard let code = code else { return false }
        return adminAndId.keys.contains(code)
    }
    
    func getCode(id: String) -> String? {
        adminAndId.first(where: { $0.value.id == id })?.key
    }
    
    func matchName(_ name: String) -> Bool {
        adminAndId.values.contains { $0.name.lowercased().contains(name.lowercased()) }
    }
    
    func nameToId(_ name: String) -> String? {
        adminAndId.first(where: { $0.value.name.lowercased() == name.lowercased() })?.value.id
    }
    
    func idToName(_ id: String) -> String? {
        adminAndId.first(where: { $0.value.id.lowercased() == id.lowercased() })?.value.name
    }
    
    func idToTier(_ id: String) -> Int? {
        adminAndId.first(where: { $0.value.id.lowercased() == id.lowercased() })?.value.tier
    }
}




