//
//  WelcomeView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//

import SwiftUI

/// Intro screen that displays animated text before transitioning to login
struct WelcomeView: View {
    @StateObject var viewManager: ViewManager
    @State private var displayedText = ""
    
    let locFuncs = LocFuncs()
    
    private let fullText = "Welcome to MiniMate"
    private let typingSpeed = 0.05 // Time interval between each character
    
    /// Avoids re-triggering transition multiple times
    @State private var animationTriggered = false

    var body: some View {
        ZStack {
            // Background gradient
            Rectangle()
                .foregroundStyle(Gradient(colors: [.blue, .teal]))
                .ignoresSafeArea()

            // Content
            VStack(spacing: 30) {
                // Typing Text
                Text(displayedText)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundStyle(.white)
                    .onAppear {
                        startTypingAnimation()
                    }

                // Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
        }
        .onAppear {
            //locFuncs.deletePersistentStore()
        }
    }

    /// Animates each character with delay, then navigates to login screen
    func startTypingAnimation() {
        displayedText = ""

        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed * Double(index)) {
                displayedText.append(character)

                if displayedText == fullText, !animationTriggered {
                    animationTriggered = true
                    withAnimation {
                        viewManager.navigateToLogin()
                    }
                }
            }
        }
    }
}
