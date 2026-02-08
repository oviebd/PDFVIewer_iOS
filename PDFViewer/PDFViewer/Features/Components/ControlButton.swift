//
//  ControlButton.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 28/5/25.
//

import SwiftUI

struct ControlButton: View {
    var systemName: String
    var color: Color = AppColors.background
    var foreground: Color = AppColors.textPrimary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(AppFonts.controlButton)
                .padding()
                .background(color.opacity(0.9))
                .foregroundColor(foreground)
                .clipShape(Circle())
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        ControlButton(systemName: "plus") {
        }
        ControlButton(systemName: "minus", color: AppColors.primary, foreground: AppColors.onPrimary) {
            print("Minus tapped")
        }
        ControlButton(systemName: AppImages.download, color: AppColors.success, foreground: AppColors.onPrimary) {
        }
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
