//
//  DonationOption.swift
//  MiniMate
//
//  Created by Garrett Butchko on 4/30/25.
//


import SwiftUI
import StoreKit

struct DonationOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: String
    let productID: String
    let color: Color
}

extension Notification.Name {
    static let didCompleteDonation = Notification.Name("didCompleteDonation")
}

struct DonationView: View {
    @State private var products: [Product] = []
    @State private var showCustom = false
    @State private var thankYou = false
    @State private var errorMessage: String?
    
    let options: [DonationOption] = [
        .init(title: "Quick Sip", subtitle: "A refreshing $1 boost", amount: "$0.99", productID: "donation_1", color: .blue),
        .init(title: "Tall Cup", subtitle: "Enough to power an extra bug fix", amount: "$4.99", productID: "donation_5", color: .green),
        .init(title: "Full Pitcher", subtitle: "You're the MVP 🙌", amount: "$9.99", productID: "donation_10", color: .orange)
    ]
    
    var body: some View {
        
        Capsule()
            .frame(width: 38, height: 6)
            .foregroundColor(.gray)
            .padding(10)
        
        ScrollView{
            VStack(spacing: 24) {
                
                Text("Support MiniMate")
                    .font(.largeTitle.bold())
                    .padding(.top)
                
                Text("Your support helps me keep building awesome features. Thank you! 🙏")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ForEach(options) { option in
                    Button {
                        if option.productID == "donation_custom" {
                            showCustom = true
                        } else {
                            Task {
                                await purchase(productID: option.productID)
                            }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(option.title)
                                    .font(.headline)
                                    .foregroundStyle(option.color)
                                Text(option.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(option.amount)
                                .font(.headline)
                                .foregroundStyle(option.color)
                            
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .overlay(content: {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(style: StrokeStyle(lineWidth: 1))
                                .stroke(option.color)
                            
                        })
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal)
                }
                
                if thankYou {
                    Text("🎉 Thank you for your donation!")
                        .foregroundColor(.green)
                        .padding(.top)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
                
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("A Word from the Developer")
                            .font(.headline)
                            .padding(.bottom)
                        
                        Text("""
                Hi! I'm Garrett, a 19-year-old indie developer from Ohio. I built MiniMate to make tracking mini golf stats fun and simple — and as a passion project to grow my skills. If you feel inclined to donate, thank you so much 🙏 — or just email me with ideas to make this app better!
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
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(25)
                .padding(.horizontal)
                
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteDonation)) { note in
            if let id = note.object as? String,
               options.map(\.productID).contains(id) {
                withAnimation{
                    thankYou = true
                }
            }
        }
        .task {
            await loadProducts()
        }
    }
    
    func loadProducts() async {
        do {
            let ids = options.map { $0.productID }
            print("Fetched IAP IDs:", products.map { $0.id })
            products = try await Product.products(for: ids)
        } catch {
            errorMessage = "Failed to load products"
        }
    }
    
    func purchase(productID: String) async {
        guard let product = products.first(where: { $0.id == productID }) else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success:
                withAnimation{
                    thankYou = true
                }
            default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }
    
    
}
