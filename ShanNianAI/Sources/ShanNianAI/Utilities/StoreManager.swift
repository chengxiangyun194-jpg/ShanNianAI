import Foundation
import StoreKit
import SwiftUI

enum SubscriptionTier: String, CaseIterable {
    case monthly = "com.shanian.flashai.pro.monthly"
    case yearly = "com.shanian.flashai.pro.yearly"

    var displayName: String {
        switch self {
        case .monthly: return "月度"
        case .yearly: return "年度"
        }
    }

    var badge: String {
        switch self {
        case .monthly: return ""
        case .yearly: return "推荐"
        }
    }
}

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var productIDs = SubscriptionTier.allCases.map(\.rawValue)
    private var updatesTask: Task<Void, Never>?

    var isPro: Bool {
        !purchasedProductIDs.isEmpty
    }

    private init() {
        updatesTask = listenForUpdates()
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: productIDs)
            products = storeProducts.sorted { a, _ in
                // Yearly first (recommended)
                a.id.contains("yearly")
            }
        } catch {
            errorMessage = "无法加载商品信息"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    await handleTransaction(transaction)
                    HapticManager.success()
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "购买正在处理中"
            @unknown default:
                errorMessage = "未知的购买结果"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await checkEntitlements()
            HapticManager.success()
        } catch {
            errorMessage = "恢复购买失败"
        }
    }

    // MARK: - Check Entitlements

    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                await handleTransaction(transaction)
            }
        }
    }

    // MARK: - Private

    private func handleTransaction(_ transaction: StoreKit.Transaction) async {
        if let revocationDate = transaction.revocationDate {
            // Transaction revoked
            purchasedProductIDs.remove(transaction.productID)
        } else if let expirationDate = transaction.expirationDate,
                  expirationDate < Date() {
            // Expired
            purchasedProductIDs.remove(transaction.productID)
        } else {
            purchasedProductIDs.insert(transaction.productID)
        }
        await transaction.finish()
    }

    private func listenForUpdates() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await handleTransaction(transaction)
                }
            }
        }
    }
}
