//
//  NumberPickerView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/18/25.
//
import SwiftUI

struct PhotoIconView<Background: ShapeStyle>: View {
    let photoURL: URL?
    let name: String
    let imageSize: CGFloat
    var background: Background

    var body: some View {
        VStack {
            ZStack {
                /// background circle
               
                Circle()
                    .fill(background)
                    .frame(width: imageSize + 10, height: imageSize + 10)
                
                
                /// photo
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .empty:
                        Image("logoOpp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageSize, height: imageSize)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit) // show full image
                            .frame(width: imageSize, height: imageSize)
                            .clipShape(Circle()) // still keeps the round shape
                    case .failure:
                        Image(systemName: "logoOpp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageSize, height: imageSize)
                    @unknown default:
                        Image(systemName: "logoOpp")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageSize, height: imageSize)
                    }
                }
            }
            /// Name on the bottom
            Text(name)
                .font(imageSize >= 30 ? .caption : .caption2)
                .foregroundStyle(.mainOpp)
        }
    }
}

