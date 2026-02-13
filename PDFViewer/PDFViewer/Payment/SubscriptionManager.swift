//
//  SubscriptionManager.swift
//  Silento_FocusManagementAPP
//
//  Created by Auto-Agent on 18/1/26.
//

import Foundation
import RevenueCat
import Combine

struct SubscriptionInfo: Identifiable {
    let id = UUID()
    let productId: String
    let name: String
    let price: String
    let expirationDate: Date?
    let willRenew: Bool
    let isActive: Bool
    let period: String
}

class SubscriptionManager: ObservableObject {
    
    static let shared = SubscriptionManager()
    
    @Published var isPremium: Bool = false
    @Published var currentPlanName: String = "Free"
    @Published var subscriptionExpirationDate: Date? = nil
    @Published var subscriptionInfo: SubscriptionInfo?
    
    var planDisplayName: String {
        return subscriptionInfo?.name ?? currentPlanName
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe CustomerInfo changes to update premium status
        Task {
            for await info in Purchases.shared.customerInfoStream {
                await self.updateSubscriptionStatus(info: info)
            }
        }
    }
    
    @MainActor
    private func updateSubscriptionStatus(info: CustomerInfo) {
        let entitlement = info.entitlements[RevenueCatConfig.entitlementId]
        let hasPremium = entitlement?.isActive == true
        self.isPremium = hasPremium
        self.subscriptionExpirationDate = entitlement?.expirationDate
        
        if !hasPremium {
            self.currentPlanName = "Free"
            self.subscriptionInfo = nil
        } else {
            guard let productId = entitlement?.productIdentifier else {
                self.currentPlanName = "Premium Subscription"
                return
            }
            
            // Set plan name immediately based on ID (fallback/immediate)
            switch productId {
            case RevenueCatConfig.Products.monthly:
                self.currentPlanName = "Monthly Subscription"
            case RevenueCatConfig.Products.yearly:
                self.currentPlanName = "Yearly Subscription"
            case RevenueCatConfig.Products.lifetime:
                self.currentPlanName = "Lifetime Access"
            default:
                self.currentPlanName = "Premium Subscription"
            }
            
            // Fetch detailed info
            if let entitlement = entitlement {
                fetchProductDetails(for: productId, entitlement: entitlement)
            }
        }
    }
    
    private func fetchProductDetails(for productId: String, entitlement: EntitlementInfo) {
        Purchases.shared.getOfferings { [weak self] offerings, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                guard let offerings = offerings,
                      let currentOffering = offerings.current else {
                    return
                }
                
                // Find the matching product
                if let package = currentOffering.availablePackages.first(where: {
                    $0.storeProduct.productIdentifier == productId
                }) {
                    let product = package.storeProduct
                    
                    var period = "Unknown"
                    if let subscriptionPeriod = product.subscriptionPeriod {
                         period = "\(subscriptionPeriod.value) \(subscriptionPeriod.unit)"
                    }
                    
                    self.subscriptionInfo = SubscriptionInfo(
                        productId: productId,
                        name: product.localizedTitle,
                        price: product.localizedPriceString,
                        expirationDate: entitlement.expirationDate,
                        willRenew: entitlement.willRenew,
                        isActive: entitlement.isActive,
                        period: period
                    )
                    
                    // Optionally update currentPlanName to the localized title from store
                    self.currentPlanName = product.localizedTitle
                }
            }
        }
    }
    
    // MARK: - Limits

    var maxPDFImportsAllowed: Int {
        return isPremium ? .max : 5
    }

    var maxFoldersAllowed: Int {
        return isPremium ? .max : 1
    }

    var isExportAllowed: Bool {
        return isPremium
    }

    var isAnnotationHistoryAllowed: Bool {
        return isPremium
    }

    var isFavoriteAllowed: Bool {
        return isPremium
    }

    var isGoToPageAllowed: Bool {
        return isPremium
    }

    // MARK: - Helper Checks

    func canImportPDF(currentCount: Int) -> Bool {
        return currentCount < maxPDFImportsAllowed
    }

    func canCreateFolder(currentCount: Int) -> Bool {
        return currentCount < maxFoldersAllowed
    }
}
