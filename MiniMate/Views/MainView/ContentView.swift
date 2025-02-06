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
    
    var body: some View {
        VStack {
            switch viewManager.currentView {
            case .main:
                MainView(authViewModel: authViewModel, viewManager: viewManager)
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
