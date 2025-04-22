//
//  ViewManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

/// Manages app navigation state based on authentication status
@MainActor
class ViewManager: ObservableObject {
    /// Defines all possible views the app can present
    enum ViewType: Equatable {
        case main
        case login
        case signup
        case welcome
        case scoreCard(GameModel)
    }

    /// Currently active view (used to drive view switching in ContentView)
    @Published var currentView: ViewType

    /// Initializes view based on whether a Firebase user is currently logged in
    init() {
        if Auth.auth().currentUser != nil {
            self.currentView = .main
        } else {
            self.currentView = .welcome
        }
    }

    /// Navigate to main app view (after login/signup)
    func navigateToMain() {
        currentView = .main
    }

    /// Navigate to login view
    func navigateToLogin() {
        currentView = .login
    }

    /// Navigate to signup view
    func navigateToSignUp() {
        currentView = .signup
    }

    /// Navigate to welcome view (usually first time or logout)
    func navigateToWelcome() {
        currentView = .welcome
    }
    
    /// Navigate to welcome view (usually first time or logout)
    func navigateScoreCard(gameModel: GameModel) {
        currentView = .scoreCard(gameModel)
    }
}

