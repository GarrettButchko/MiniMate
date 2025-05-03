// ProfileView.swift
// MiniMate
//
// Updated to use UserModel and AuthViewModel

import SwiftUI
import FirebaseAuth

/// Displays and allows editing of the current user's profile
struct GameInfoView: View {
    
    @Binding var game: Game
    @Binding var isSheetPresent: Bool

    var body: some View {
        ZStack {
            VStack {
                // Header and drag indicator
                Capsule()
                    .frame(width: 38, height: 6)
                    .foregroundColor(.gray)
                    .padding(10)

                HStack {
                    Text("Game Info")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.leading, 30)
                    Spacer()
                }

                List {
                    Section ("Info") {
                        UserInfoRow(label: "Game Code", value: game.id)
                        UserInfoRow(label: "Number of players", value: "\(game.players.count)")
                        UserInfoRow(label: "Number of holes", value: "\(game.numberOfHoles)")
                        if let location = game.location, location.latitude != 0 {
                            UserInfoRow(label: "Location", value: "\(location.name ?? "No Name")")
                        }
                    }
                }
            }
        }
    }
}
