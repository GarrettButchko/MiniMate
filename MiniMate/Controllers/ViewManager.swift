//
//  ViewManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

class ViewManager: ObservableObject {
    @Published var currentView: ViewType
    
    enum ViewType {
        case main
        case profile
        case login
    }
    
    init() {
        // Check if a user is logged in
        if Auth.auth().currentUser != nil {
            self.currentView = .main
        } else {
            self.currentView = .login
        }
    }
    
    func navigateToMain() {
        currentView = .main
    }
    
    func navigateToProfile() {
        currentView = .profile
    }
    
    func navigateToLogin() {
        currentView = .login
    }
}

