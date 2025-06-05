//
//  DonationOption.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/30/25.
//

import SwiftUI
import StoreKit

struct ProView: View {
    @State private var thankYou = false
    @State private var errorMessage: String?
    @Binding var showSheet: Bool
    @ObservedObject var authModel: AuthViewModel
    @StateObject var iapManager = IAPManager()
    
    
    
    let benefits = [
        "Ad-free experience",
        "Early access to new content",
        "More Coming soon..."
    ]
    
    var body: some View {
        
        Capsule()
            .frame(width: 38, height: 6)
            .foregroundColor(.gray)
            .padding(10)
        
        ScrollView{
            VStack(spacing: 24) {
                
                Text("Buy Pro Now!")
                    .font(.largeTitle.bold())
                    .padding(.top)
                
                Text("Your support helps me keep building awesome features. Thank you! 🙏")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ZStack{
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.ultraThinMaterial)
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(benefits, id: \.self) { benefit in
                            HStack() {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.yellow)
                                Text(benefit)
                                    .font(.headline)
                                Spacer()
                            }
                            
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("A Word from the Developer")
                            .font(.headline)
                            .padding(.bottom)
                        
                        Text("""
                Hi! I'm Garrett, a 19-year-old indie developer from Ohio. I built MiniMate to make tracking mini golf stats fun and simple — and as a passion project to grow my skills. If you feel inclined to buy, thank you so much 🙏 — or just email me with ideas to make this app better!
                """)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Image("mePhoto")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                        
                        Text("Garrett Butchko")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Button(action: {
                            if let url = URL(string: "mailto:circuit.leaf1@gmail.com?subject=MiniMate Feedback") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("Email Me", systemImage: "envelope.fill")
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(25)
                .padding(.horizontal)
                
                if thankYou {
                    Text("🎉 Thank you for your purchase!")
                        .foregroundColor(.green)
                        .padding(.top)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Button {
                    Task {
                        await iapManager.purchase(iapManager.products[0], authModel: authModel, showSheet: $showSheet)
                    }
                } label: {
                    Text("Upgrade Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(12)
                        .shadow(color: Color.yellow, radius: 5)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                Button("Restore Purchases") {
                    Task {
                        do {
                            try await AppStore.sync()
                            // Success handling (e.g., show confirmation)
                            print("Successfully restored purchases.")
                        } catch {
                            print("Failed to restore purchases: \(error)")
                        }
                    }
                }
            }
        }
    }
}
