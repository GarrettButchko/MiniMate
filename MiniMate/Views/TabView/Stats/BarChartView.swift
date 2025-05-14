//
//  BarChartView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/13/25.
//
import SwiftUI
import Charts

struct BarChartView: View {
    @Environment(\.colorScheme) private var colorScheme
    let data: [Hole]
    let title: String

    var body: some View {
        Chart {
            ForEach(data, id: \.self) { dataPoint in
                BarMark(
                    x: .value("Hole", dataPoint.number),
                    y: .value("Strokes", dataPoint.strokes)
                )
                .annotation(position: .top) { // Adds stroke count above bar
                    Text("\(dataPoint.strokes)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: [.blue, .green]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .stride(by: 3)) { value in
                AxisValueLabel {
                    if let hole = value.as(Int.self) {
                        Text("H\(hole)") // Shows "H1", "H2", etc.
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 5))
        }
        .chartXAxisLabel(position: .bottom, alignment: .center) {
          Text(title)
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .chartXScale(domain: data.isEmpty ? 0...1 : 1...data.count)
        .chartYScale(domain: 0...(data.map { $0.strokes }.max() ?? 10) + 1)
        .frame(height: 75)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(colorScheme == .light
                                                            ? AnyShapeStyle(Color.white)
                                                            : AnyShapeStyle(.ultraThinMaterial)))
    }
}
