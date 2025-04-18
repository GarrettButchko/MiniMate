//
//  MainView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 1/31/25.
//

import SwiftUI

/// The main screen after login, showing user profile access and primary actions
struct MainView: View {
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthModel

    /// Controls profile sheet presentation
    @State private var isSheetPresented = false
    
    /// Comtrols reauthenticate overlay
    @State var showLoginOverlay = false

    /// The logged-in user's data
    @Binding var userModel: UserModel?

    var body: some View {
            VStack {
                // MARK: - Top Bar with Profile Button
                HStack {
                    Button(action: {
                        isSheetPresented = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.primary)
                        }
                    }
                    .sheet(isPresented: $isSheetPresented) {
                        ProfileView(
                            viewManager: viewManager,
                            authModel: authModel,
                            isSheetPresent: $isSheetPresented,
                            userModel: $userModel,
                            showLoginOverlay: $showLoginOverlay
                        )
                    }
                    
                    Spacer()
                }
                
                // MARK: - Title Area
                TitleView()
                    .frame(width: 300, height: 220)
                
                // MARK: - Quick Start Button
                Button {
                    // TODO: Start a quick round
                } label: {
                    ZStack {
                        Capsule()
                            .frame(width: 200, height: 50)
                            .foregroundStyle(.blue)
                        Text("Quick Start")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.top)
                
                HStack(spacing: 16) {
                    RoundedRectangle(cornerSize: CGSize(width: 30, height: 30))
                        .foregroundStyle(.ultraThinMaterial)
                        .frame(height: 175)
                    
                    RoundedRectangle(cornerSize: CGSize(width: 30, height: 30))
                        .foregroundStyle(.ultraThinMaterial)
                        .frame(height: 175)
                }
                .padding(.vertical)
                
                Spacer()
            }
            .padding()
    }
}
