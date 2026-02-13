import SwiftUI
import Combine

class SubscriptionPlanViewModel: ObservableObject {
    
    // Use the singleton of the subscriptionManager
    private let subscriptionManager = SubscriptionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPremium: Bool = false
    @Published var currentPlanName: String = "Free"
    @Published var expirationDate: Date? = nil
    
    // MARK: - Alert States
    @Published var isShowingPremiumAlert: Bool = false
    @Published var isShowingPaywall: Bool = false
    @Published var premiumAlertTitle: String = "Upgrade Required"
    @Published var premiumAlertMessage: String = ""
    
    init() {
        // Observe changes from SubscriptionManager singleton
        isPremium = subscriptionManager.isPremium
        currentPlanName = subscriptionManager.planDisplayName
        expirationDate = subscriptionManager.subscriptionExpirationDate
        
        subscriptionManager.$isPremium
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPremium, on: self)
            .store(in: &cancellables)
        
        // Sync plan display name
        subscriptionManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.currentPlanName = self.subscriptionManager.planDisplayName
                self.expirationDate = self.subscriptionManager.subscriptionExpirationDate
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Warnings Logic
    
    // MARK: - Warnings Logic

    func pdfImportLimitWarning(currentCount: Int) -> String? {
        if !isPremium && !subscriptionManager.canImportPDF(currentCount: currentCount) {
            return "Free users can import up to \(subscriptionManager.maxPDFImportsAllowed) PDFs. Upgrade to Premium for unlimited access."
        }
        return nil
    }

    func folderLimitWarning(currentCount: Int) -> String? {
        if !isPremium && !subscriptionManager.canCreateFolder(currentCount: currentCount) {
            return "Free users can create only one folder. Upgrade to Premium for unlimited folders."
        }
        return nil
    }

    var exportRestrictedMessage: String {
        return "Export is a Premium feature. Upgrade to enable PDF exporting."
    }

    var annotationHistoryRestrictedMessage: String {
        return "Undo/Redo for annotations is a Premium feature. Upgrade to enable it."
    }

    var favoriteRestrictedMessage: String {
        return "Favoriting PDFs is a Premium feature. Upgrade to enable it."
    }

    var goToPageRestrictedMessage: String {
        return "Go to Page (by type) is a Premium feature. Upgrade to enable it."
    }

    // MARK: - Logic Helpers

    func canImportMorePDFs(currentCount: Int) -> Bool {
        return isPremium || subscriptionManager.canImportPDF(currentCount: currentCount)
    }

    func canCreateMoreFolders(currentCount: Int) -> Bool {
        return isPremium || subscriptionManager.canCreateFolder(currentCount: currentCount)
    }

    func showPremiumAlert(title: String = "Upgrade Required", message: String) {
        premiumAlertTitle = title
        premiumAlertMessage = message
        isShowingPremiumAlert = true
    }
    
    func manageSubscriptions() {
        #if os(iOS)
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
