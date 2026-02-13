import SwiftUI
import RevenueCat
import RevenueCatUI

struct PlanPage: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                PaywallView(displayCloseButton: false)
                    .onPurchaseCompleted { _ in
                        dismiss()
                    }
                    .onRestoreCompleted { _ in
                        dismiss()
                    }
            }
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.secondary)
                    .padding()
            }
            .padding(.top, 10)
            .padding(.trailing, 10)
        }
        .ignoresSafeArea(.all, edges: .top)
    }
}

#Preview {
    PlanPage()
}
