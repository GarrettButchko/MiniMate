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
    let course: Course?
    
    @StateObject private var viewManager = ViewManagerClip()
    @StateObject private var authModel: AuthViewModelClip
    @StateObject private var gameModel: GameViewModelClip
    
    let locFuncs = LocFuncs()
    
    @State var ad: Ad? = nil
    
    @State private var previousView: ViewType?
    @State private var hasLoadedUser = false
    
    init(course: Course?){
        self.course = course
        
        // 1) create your AuthViewModel first
        let auth = AuthViewModelClip()
        _authModel = StateObject(wrappedValue: auth)
        
        // 2) create an initial Game (or fetch one from your context)
        print("Initializing game...: \(course?.numOfHoles ?? 0)")
        
        
        let initialGame =  Game(id: "", date: Date(), completed: false, numberOfHoles: course?.numOfHoles ?? 18, started: false, dismissed: false, live: false, lastUpdated: Date(), courseID: course?.id ,players: [])
        
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
        .onAppear {
            guard let course else {
                print("⛔️ No course available, skipping ad fetch")
                return
            }

            Task {
                do {
                    ad = nil
                    let url = URL(string: "https://circuit-leaf.com/mini-mate/api/ads.json")!
                    let ads: [Ad] = try await url.fetchAndDecode()

                    for ad in ads {
                        print("Comparing course ID: \(course.id) with ad ID: \(ad.id)")
                        if course.id == ad.id {
                            self.ad = ad
                            print("✅ Found matching ad: \(ad.title)")
                        }
                    }
                } catch {
                    print("❌ Failed to fetch or decode ads: \(error.localizedDescription)")
                    ad = nil
                }
            }
        }

    }
    
    @ViewBuilder
    var activeView: some View {
        switch viewManager.currentView {
        case .main:
            MainViewClip(course: course, ad: $ad, viewManager: viewManager, authModel: authModel, gameModel: gameModel)
                .onAppear {
                    authModel.loadOrCreateUserIfNeeded(in: context){
                        try? context.save()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        authModel.loadOrCreateUserIfNeeded(in: context){
                            try? context.save()
                        }
                    }
                }
            
        case .scoreCard:
            ScoreCardViewClip(ad: $ad, viewManager: viewManager, authModel: authModel, gameModel: gameModel)
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
