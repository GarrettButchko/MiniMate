//
//  CustomDonationView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/30/25.
//
import SwiftUI
import StoreKit

struct CustomDonationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var amount: String = ""

    var body: some View {
        VStack(spacing: 20) {
            
            Capsule()
                .frame(width: 38, height: 6)
                .foregroundColor(.gray)
                .padding(10)
            
            Text("Custom Donation")
                .font(.title2.bold())
            TextField("Enter amount in USD", text: $amount)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)

            Button("Submit") {
                // Handle custom donation logic (external link or log it)
                dismiss()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}
