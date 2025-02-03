//
//  Untitled.swift
//  MiniMate
//
//  Created by Garrett Butchko on 1/31/25.
//

import SwiftUI

struct TitleView: View {
    @State private var time: Double = 0  // Animation time

    let orbitingCircles: [OrbitingCircle] = (0..<8).map { index in  //Generate circles
        
        let colors = [Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple, Color.indigo, Color.pink]
        
        return OrbitingCircle(
            angleOffset: Double(index) * (360 / 8),
            size: Double.random(in: 10...20),
            speedMultiplier: Double.random(in: 0.8...1.2),
            color: colors[index]
        )
    }

    var body: some View {
        ZStack {
            
            VStack{
                HStack{
                    Text("Mini")
                        .font(.largeTitle)
                        .foregroundColor(.mainOpp)
                        .bold()
                        .zIndex(1)
                    Spacer()
                }
                HStack{
                    Spacer()
                    Text("Mate")
                        .font(.largeTitle)
                        .foregroundColor(.mainOpp)
                        .bold()
                        .zIndex(1)
                }
            }
            .frame(width: 130)
            

            TimelineView(.animation) { timeline in
                let date = timeline.date.timeIntervalSinceReferenceDate
                let rotationAngle = date * 50  // Speed of orbit

                ForEach(orbitingCircles, id: \.angleOffset) { circle in
                    let angle = rotationAngle * circle.speedMultiplier + 120
                    let radians = angle * .pi / 180

                    let x = 100 * cos(radians)  // Orbit radius (horizontal)
                    let y = sin(radians) // Orbit radius (vertical)

                    let depth = sin(radians)  // Simulate depth by scaling
                    let scale = 0.5 + 0.5 * (1 + depth)  // Scale from 0.5 to 1

                    Circle()
                        .fill(circle.color)
                        .frame(width: circle.size * scale, height: circle.size * scale)
                        .offset(x: x, y: y)
                        .opacity(0.5 + 0.5 * scale)  // Adjust opacity for depth
                }
            }
        }
    }
}

// Struct for Orbiting Circles
struct OrbitingCircle {
    let angleOffset: Double
    let size: Double
    let speedMultiplier: Double
    let color: Color
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TitleView()
    }
}
