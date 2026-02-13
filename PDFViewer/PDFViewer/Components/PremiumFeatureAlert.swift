//
//  PremiumFeatureAlert.swift
//  PDFViewer
//
//  Created by Habibur_Periscope on 13/2/26.
//

import SwiftUI

struct PremiumFeatureAlert: View {
    let title: String
    let message: String
    let onUpgrade: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Alert Card
            VStack(spacing: 20) {
                // Icon
                ZStack {
//                    Circle()
//                        .fill(
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.primaryPurple, Color.secondaryPurple]),
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                        .frame(width: 70, height: 70)
//                        .shadow(color: Color.primaryPurple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
                
                // Title
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                
                // Message
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                // Buttons
                HStack(spacing: 12) {
                    // Cancel Button
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(14)
                    }
                    
                    // Upgrade Button
                    Button(action: onUpgrade) {
                        Text("Upgrade")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.green]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 320)
            .background(AppColors.cardBackground)
            .cornerRadius(24)
           // .shadow(color: AppColors.shadow, radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - View Extension for Easy Use

extension View {
    func premiumFeatureAlert(
        isPresented: Binding<Bool>,
        title: String = "Premium Feature",
        message: String,
        onUpgrade: @escaping () -> Void
    ) -> some View {
        ZStack {
            self
            
            if isPresented.wrappedValue {
                PremiumFeatureAlert(
                    title: title,
                    message: message,
                    onUpgrade: {
                        isPresented.wrappedValue = false
                        onUpgrade()
                    },
                    onCancel: {
                        isPresented.wrappedValue = false
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented.wrappedValue)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        
        PremiumFeatureAlert(
            title: "Premium Feature",
            message: "Free users can create only one profile.\nUpgrade to Premium to add more profiles.",
            onUpgrade: { print("Upgrade tapped") },
            onCancel: { print("Cancel tapped") }
        )
    }
}
