//
//  NumberPickerView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/18/25.
//
import SwiftUI

struct PhotoIconView: View {
    let photoURL: URL?
    let name: String

    var body: some View {
        VStack {
            ZStack {
                /// background circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                /// photo
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .empty:
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit) // show full image
                            .frame(width: 30, height: 30)
                            .clipShape(Circle()) // still keeps the round shape
                    case .failure:
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    @unknown default:
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            /// Name on the bottom
            Text(name)
                .font(.caption)
        }
    }
}

