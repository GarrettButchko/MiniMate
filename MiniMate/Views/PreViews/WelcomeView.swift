//
//  WelcomeView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//

import SwiftUI

/// Intro screen that displays animated text before transitioning to login
struct WelcomeView: View {
    @ObservedObject var viewManager: ViewManager
    @State private var displayedText = ""
    
    let locFuncs = LocFuncs()
    
    private let fullText = "Welcome to MiniMate"
    private let typingSpeed = 0.05 // Time interval between each character
    
    /// Avoids re-triggering transition multiple times
    @State private var animationTriggered = false
    
    @State var showLoading = false

    var body: some View {
        ZStack {
            // Background gradient
            Rectangle()
                .foregroundStyle(Gradient(colors: [.blue, .green]))
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
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .colorScheme(.light)
                
                if showLoading{
                    Text("Trying to reconnect...")
                        .foregroundStyle(.white)
                        .onAppear {
                            pollUntilInternet()
                        }
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5) // optional: make it bigger
                }
            }
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
                    if NetworkChecker.shared.isConnected{
                        withAnimation {
                            viewManager.navigateToLogin()
                        }
                    } else {
                        showLoading = true
                    }
                }
            }
        }
    }
    
    func pollUntilInternet() {
            // Run the check right away
        if NetworkChecker.shared.isConnected {
            withAnimation {
                viewManager.navigateToLogin()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                pollUntilInternet()
            }
        }
    }
}
