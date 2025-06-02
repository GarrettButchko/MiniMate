//
//  StoreManager.swift
//  MiniMate
//
//  Created by Garrett Butchko on 6/1/25.
//

import Foundation
import Combine
import StoreKit

class StoreManager: ObservableObject{
    @Published var products: [Product] = []
    private var authModel: AuthViewModel
    private let proProductID = "com.minimate.pro"

    init(authModel: AuthViewModel) {
        self.authModel = authModel
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [proProductID])
            self.products = storeProducts
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchasePro(_ product: Product) async {
        guard product.id == proProductID else {
            print("Attempted to purchase unsupported product: \(product.id)")
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    if transaction.productID == proProductID {
                        await updatePurchasedProducts()
                    }
                case .unverified(_, let error):
                    print("Purchase failed verification: \(error)")
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase error: \(error)")
        }
    }
    
    @MainActor
    func updatePurchasedProducts() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == proProductID {
                hasPro = true
                break
            }
        }
            self.authModel.userModel?.isPro = hasPro
            self.authModel.saveUserModel(self.authModel.userModel!) { _ in }
    }

    func isPurchased() -> Bool {
        return authModel.userModel?.isPro ?? false
    }
}
