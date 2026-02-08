//
//  EmptyStateView.swift
//  PDFViewer
//
//  Created by Habibur Rahman
//

import SwiftUI

struct EmptyStateView: View {
    let onImport: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            
            // Icon
            Image(systemName: AppImages.document)
                .font(AppFonts.iconXLarge)
                .foregroundColor(AppColors.placeholder)
            
            // Title and subtitle
            VStack(spacing: AppSpacing.xs) {
                Text(AppStrings.EmptyState.title)
                    .emptyStateTitleStyle()
                
                Text(AppStrings.EmptyState.subtitle)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Import button
            Button(action: onImport) {
                Text(AppStrings.EmptyState.importButton)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.onPrimary)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMD)
                            .fill(AppColors.primary)
                    )
            }
            .padding(.top, AppSpacing.xs)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview {
    EmptyStateView(onImport: {})
}
