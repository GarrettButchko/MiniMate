//
//  ContentView.swift
//  MiniMate Clip
//
//  Created by Garrett Butchko on 5/12/25.
//

import SwiftUI
import SwiftData

struct ContentViewClip: View {
    @Environment(\.modelContext) var context
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var viewManager = ViewManagerClip()
    @StateObject private var authModel: AuthViewModelClip
    @StateObject private var gameModel: GameViewModelClip
    
    let locFuncs = LocFuncs()
    
    @State private var previousView: ViewType?
    @State private var hasLoadedUser = false
    
    init() {
        // 1) create your AuthViewModel first
        let auth = AuthViewModelClip()
        _authModel = StateObject(wrappedValue: auth)
        
        // 2) create an initial Game (or fetch one from your context)
        let initialGame =  Game(id: "", date: Date(), completed: false, numberOfHoles: 18, started: false, dismissed: false, live: false, lastUpdated: Date(), holes: [], players: [])
        
        // 3) now inject both into your GameViewModel
        _gameModel = StateObject(
            wrappedValue: GameViewModelClip(
                auth: auth, game: initialGame
            )
        )
    }
    
    var body: some View {
        ZStack {
            activeView
                .transition(currentTransition)
                .animation(.easeInOut(duration: 0.4), value: viewManager.currentView)
                .onChange(of: viewManager.currentView, { oldValue, newValue in
                    previousView = viewManager.currentView
                })
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch newPhase {
                    case .active:
                        print("App is active")
                        try? context.save()
                    case .inactive:
                        print("App is inactive")
                        try? context.save()
                    case .background:
                        print("App moved to background")
                        try? context.save()
                    @unknown default:
                        break
                    }
                }
        }
        
    }
    
    @ViewBuilder
    var activeView: some View {
        switch viewManager.currentView {
        case .main:
            MainViewClip(viewManager: viewManager, authModel: authModel, gameModel: gameModel)
                .onAppear {
                    authModel.loadOrCreateUserIfNeeded(in: context){
                        try? context.save()
                    }
                }
            
        case .scoreCard:
            ScoreCardViewClip(viewManager: viewManager, authModel: authModel, gameModel: gameModel)
        }
    }
    
    // MARK: - Custom transition based on view switch
    var currentTransition: AnyTransition {
        switch (previousView, viewManager.currentView) {
        case (_, .main):
            return .opacity.combined(with: .scale)
        default:
            return .opacity
        }
    }
}

#Preview {
    ContentViewClip()
}
