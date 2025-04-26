//
//  ViewManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

enum ViewType {
    case main
    case login
    case signup
    case welcome
    case scoreCard(Binding<GameModel>)
}

/// Manages app navigation state based on authentication status
@MainActor
class ViewManager: ObservableObject {
    

    @Published var currentView: ViewType

    init() {
        if Auth.auth().currentUser != nil {
            self.currentView = .main
        } else {
            self.currentView = .welcome
        }
    }

    func navigateToMain() {
        currentView = .main
    }

    func navigateToLogin() {
        currentView = .login
    }

    func navigateToSignUp() {
        currentView = .signup
    }

    func navigateToWelcome() {
        currentView = .welcome
    }
    
    func navigateToScoreCard(_ gameModel: Binding<GameModel>) {
        currentView = .scoreCard(gameModel)
    }
    
}

extension ViewType: Equatable {
    static func == (lhs: ViewType, rhs: ViewType) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main),
             (.login, .login),
             (.signup, .signup),
             (.welcome, .welcome),
             (.scoreCard, .scoreCard):
            return true
        default:
            return false
        }
    }
}




