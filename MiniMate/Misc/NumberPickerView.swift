//
//  NumberPickerView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/18/25.
//
import SwiftUI

struct NumberPickerView: View {
    @Binding var selectedNumber: Int  // 👈 make it a binding to pass value out
    let maxNumber: Int

    var body: some View {
        VStack {
            Picker("Select a number", selection: $selectedNumber) {
                ForEach(1...maxNumber, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 95)
        }
    }
}

