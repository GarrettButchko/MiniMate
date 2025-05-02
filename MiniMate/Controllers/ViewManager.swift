//
//  ViewManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

enum ViewType {
    case main(Int)
    case login
    case signup
    case welcome
    case scoreCard
    case gameReview(Game)
}

/// Manages app navigation state based on authentication status
@MainActor
class ViewManager: ObservableObject {
    

    @Published var currentView: ViewType

    init() {
        if Auth.auth().currentUser != nil {
            self.currentView = .main(1)
        } else {
            self.currentView = .welcome
        }
    }

    func navigateToMain(_ tab: Int) {
        currentView = .main(tab)
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
    
    func navigateToScoreCard() {
        currentView = .scoreCard
    }
    
    func navigateToGameReview(_ gameModel: Game) {
        currentView = .gameReview(gameModel)
    }
    
}

extension ViewType: Equatable {
    static func == (lhs: ViewType, rhs: ViewType) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main),
             (.login, .login),
             (.signup, .signup),
             (.welcome, .welcome),
            (.scoreCard, .scoreCard),
            (.gameReview, .gameReview):
            return true
        default:
            return false
        }
    }
}
