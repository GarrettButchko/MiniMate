//
//  ContentView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 1/31/25.
//

import SwiftUI

struct MainView: View {
    
    @State private var isSheetPresented = false
    @StateObject var authViewModel: AuthViewModel
    @StateObject var viewManager: ViewManager
    
    var body: some View {
        VStack {
            HStack{
                ZStack{
                    RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                        .frame(width: 200, height: 40)
                        .foregroundStyle(.ultraThickMaterial)
                    Text("Leader Board 🥇")
                        .foregroundStyle(.yellow)
                }
                
                Spacer()
                
                Button(action: {
                    isSheetPresented = true
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        Image(systemName: "person.fill")
                            .resizable()
                            .foregroundColor(.primary)
                            .frame(width: 20, height: 20)
                    }
                }
                .sheet(isPresented: $isSheetPresented) {
                    ProfileView(viewManager: viewManager, authViewModel: authViewModel)
                }
                
            }
            
            
            TitleView()
                .frame(width: 300, height: 220)
        
            Button {
                
            } label:{
                ZStack{
                    Capsule()
                        .frame(width: 200, height: 50)
                        .foregroundStyle(.green)
                    Text("Quick Start")
                        .foregroundStyle(.white)
                }
            }
            
            HStack{
                
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
