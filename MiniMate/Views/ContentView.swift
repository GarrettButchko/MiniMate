//
//  ContentView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/3/25.
//

import SwiftUI
import FirebaseAuth
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    
    @StateObject var viewManager = ViewManager()
    @StateObject var authModel = AuthModel()
    
    let locFuncs = LocFuncs()
    
    @State var selectedTab = 1
    @State var user : UserModel?
    @State private var isConnected = false
    
    var body: some View {
        VStack {
            switch viewManager.currentView {
            case .main:
                
                TabView(selection: $selectedTab){
                    
                    StatsView(viewManager: viewManager)
                        .tabItem {
                            Label("Stats", systemImage: "chart.bar.xaxis")
                        }
                        .tag(0)
                    
                    MainView(viewManager: viewManager, authViewModel: authModel, userModel: $user)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(1)
                   if isConnected {
                       CourseView(viewManager: viewManager)
                           .tabItem {
                               Label("Courses", systemImage: "figure.golf")
                           }
                           .tag(2)
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .opacity))
                .onAppear(){
                    if let userModelTest = locFuncs.fetchTask(by: authModel.user!.uid, context: context) {
                        user = userModelTest
                    } else {
                        fatalError("User not in Local Database!!!")
                    }
                }
            case .login:
                LoginView(viewManager: viewManager, authModel: authModel, userModel: $user)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            case .signup:
                SignUpView(viewManager: viewManager, authViewModel: authModel, userModel: $user)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            case .welcome:
                WelcomeView(viewManager: viewManager)
                    .transition(.opacity)
            }
        }
        .onAppear {
            isConnected = NetworkChecker.shared.isConnected
            //locFuncs.deletePersistentStore()
        }
    }
}
