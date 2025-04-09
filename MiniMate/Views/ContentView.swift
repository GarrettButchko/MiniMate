//
//  ContentView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject var viewManager = ViewManager()
    @StateObject var userData = AuthViewModel()
    @State var selectedTab = 1
    
    var body: some View {
        VStack {
            switch viewManager.currentView {
            case .main:
                
                TabView(selection: $selectedTab){
                    
                    StatsView(userData: userData, viewManager: viewManager)
                        .tabItem {
                            Label("Stats", systemImage: "chart.bar.xaxis")
                        }
                        .tag(0)
                    
                    MainView(userData: userData, viewManager: viewManager)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(1)
                    
                    CourseView(userData: userData, viewManager: viewManager)
                        .tabItem {
                            Label("Courses", systemImage: "figure.golf")
                        }
                        .tag(2)
                }
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity))
            case .login:
                LoginView(userData: userData, viewManager: viewManager)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            case .signup:
                SignUpView(userData: userData, viewManager: viewManager)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            case .welcome:
                WelcomeView(viewManager: viewManager)
                    .transition(.opacity)
            }
        }
    }
}
