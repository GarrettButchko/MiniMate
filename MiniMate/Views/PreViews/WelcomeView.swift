//
//  WelcomeView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var displayedText = ""
    @StateObject var viewManager: ViewManager
    
    let fullText = "Welcome to MiniMate"
    let typingSpeed = 0.05 // Time interval between each character
    
    var body: some View {
        
        ZStack {
            
            Rectangle()
                .foregroundStyle(Gradient(colors: [.blue, .teal]))
                .ignoresSafeArea()
        
            VStack{
                Text(displayedText)
                    .font(.largeTitle)
                    .onAppear {
                        startTypingAnimation()
                    }
                    .padding()
                    .foregroundStyle(.white)
                
                Image("Logo")
                    .resizable()
                    .frame(width: 100, height: 100)
            }
        }
    }
    
    func startTypingAnimation() {
        displayedText = ""
        
        // Create a timer that adds one character every typingSpeed interval
        for (index, character) in fullText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed * Double(index)) {
                displayedText.append(character)
                if displayedText == fullText {
                    withAnimation(){
                        viewManager.currentView = .login
                    }
                }
            }
        }
    }
}
