//
//  ViewManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI

enum ViewType {
    case main
    case scoreCard
}

/// Manages app navigation state based on authentication status
@MainActor
class ViewManagerClip: ObservableObject, @preconcurrency NavigatableViewManager {
    
    @Published var currentView: ViewType

    init() {
        self.currentView = .main
    }
    
    func navigateToMain(_ tab: Int) {
        currentView = .main
    }
    
    func navigateToScoreCard() {
        currentView = .scoreCard
    }
}

extension ViewType: Equatable {
    static func == (lhs: ViewType, rhs: ViewType) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main),
            (.scoreCard, .scoreCard):
            return true
        default:
            return false
        }
    }
}
