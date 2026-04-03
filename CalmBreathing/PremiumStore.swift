import StoreKit
import SwiftUI

// MARK: - Premium Store
@MainActor
class PremiumStore: ObservableObject {

    static let monthlyID = "com.serenebreathing.app.premium.monthly"
    static let yearlyID  = "com.serenebreathing.app.premium.yearly"

    @Published var isPremium    = false
    @Published var products:    [Product] = []
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    private var updateTask: Task<Void, Error>?

    init() {
        updateTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePremiumStatus()
        }
    }

    deinit { updateTask?.cancel() }

    // MARK: - Load products
    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: [Self.monthlyID, Self.yearlyID])
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Could not load subscription options."
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try checkVerified(verification)
                await tx.finish()
                await updatePremiumStatus()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
        }
    }

    // MARK: - Restore
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePremiumStatus()
        } catch {
            errorMessage = "Restore failed. Please try again."
        }
    }

    // MARK: - Debug override (testing only)
    func forceUnlock() {
        isPremium = true
    }

    // MARK: - Status check
    func updatePremiumStatus() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               (tx.productID == Self.monthlyID || tx.productID == Self.yearlyID),
               tx.revocationDate == nil {
                active = true
            }
        }
        isPremium = active
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let value): return value
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await tx.finish()
                    await self?.updatePremiumStatus()
                }
            }
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
