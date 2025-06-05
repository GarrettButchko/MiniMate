//
//  NavigatableViewManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/4/25.
//

import Foundation

protocol NavigatableViewManager: ObservableObject {
    func navigateToMain(_ tab: Int)
    func navigateToScoreCard()
}
