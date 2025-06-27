//
//  NavigatableViewManager 2.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/9/25.
//

import Foundation

protocol AuthViewManager: ObservableObject {
    var userModel: UserModel? { get set }
    
    func fetchCourse(id: String, completion: @escaping (Course?) -> Void)
    func addOrUpdateCourse(_ course: Course, completion: @escaping (Bool) -> Void)
}
