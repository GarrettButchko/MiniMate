//
//  CourseResolver.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/4/25.
//

import SwiftUI

final class AdminCodeResolver {
    
    static let adminAndId: [String: IdAndName] = [
        "543943": IdAndName(id: "CREATOR", name: "Creator"),
        "329742": IdAndName(id: "FC", name: "Fore Corners Mini Golf")
    ]
    
    static func isAdminCodeThere(code: String?) -> Bool {
        if let code = code {
            return adminAndId.keys.contains(code)
        } else {
            return false
        }
    }
    
    static func numOfCodes() -> Int {
        adminAndId.keys.count
    }
    
    static func getCode(id: String) -> String? {
        adminAndId.keys.first { adminAndId[$0]?.id == id }
    }
    
    static func matchName(_ name: String) -> Bool {
        adminAndId.values.contains { course in
            course.name.lowercased().contains(name.lowercased()) == true
        }
    }

    static func resolve(url: String, authModel: any AuthViewManager, completion: @escaping (Course?) -> Void) {
        let id = url.components(separatedBy: "/").last!
        authModel.fetchCourse(id: id) { course in
            completion(course)
        }
    }
    
    static func resolve(id: String?, authModel: any AuthViewManager, completion: @escaping (Course?) -> Void){
        if let id = id {
            authModel.fetchCourse(id: id) { course in
                completion(course)
            }
        } else {
            completion(nil)
        }
    }
    
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

    static func nameToId(_ name: String) -> String? {
        adminAndId.first { adminAndId[$0.key]?.name.lowercased() == name.lowercased() }?.value.id
    }
    
    static func idToName(_ id: String) -> String? {
        adminAndId.first { adminAndId[$0.key]?.id.lowercased() == id.lowercased() }?.value.name
    }
    
}

struct IdAndName{
    var id: String
    var name: String
}

