//
//  ContentView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//


//
//  ContentView.swift
//  HavenHub
//
//  Created by Garrett Butchko on 1/7/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewManager = ViewManager()
    @StateObject var authViewModel = AuthViewModel()
    @State private var selectedTab = 1
    
    var body: some View {
        VStack {
            switch viewManager.currentView {
            case .main:
                
                TabView(selection: $selectedTab){
                    
                    StatsView(authViewModel: authViewModel, viewManager: viewManager)
                        .tabItem {
                            Label("Stats", systemImage: "chart.bar.xaxis")
                        }
                        .tag(0)
                    
                    MainView(authViewModel: authViewModel, viewManager: viewManager)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(1)
                    
                    GameView(authViewModel: authViewModel, viewManager: viewManager)
                        .tabItem {
                            Label("Game", systemImage: "figure.golf")
                        }
                        .tag(2)
                }
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity))
            case .login:
                LoginView(authViewModel: authViewModel, viewManager: viewManager)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            case .signup:
                SignUpView(authViewModel: authViewModel, viewManager: viewManager)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
    }
}
