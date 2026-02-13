//
//  PurchaseManager.swift
//  Silento_FocusManagementAPP
//
//  Created by Auto-Agent on 18/1/26.
//

import Foundation
import RevenueCat

class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    @Published var customerInfo: CustomerInfo?
    
    private init() {
        Task {
            for await info in Purchases.shared.customerInfoStream {
                await MainActor.run {
                    self.customerInfo = info
                }
            }
        }
    }
    
    func restorePurchases() async throws -> CustomerInfo {
        return try await Purchases.shared.restorePurchases()
    }
}
