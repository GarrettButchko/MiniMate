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
    
    var body: some View {
        VStack {
            switch viewManager.currentView {
            case .main:
                MainView(viewManager: viewManager)
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity))
            case .profile:
                ProfileView(viewManager: viewManager, authViewModel: authViewModel)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            case .health:
                HealthView(viewManager: viewManager)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            case .login:
                LoginView(authViewModel: authViewModel, viewManager: viewManager)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            }
        }
    }
}
