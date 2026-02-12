//
//  SaveSuccessModalView.swift
//  PDFViewer
//
//  Created by Habibur_Periscope on 12/2/26.
//

import SwiftUI

struct SaveSuccessModalView: View {
    let fileName: String
    let fileLocation: String
    let onOpenLocation: () -> Void
    let onShare: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppColors.success)
            }
            .padding(.top, AppSpacing.lg)
            
            VStack(spacing: AppSpacing.xs) {
                Text("Success")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\"\(fileName)\" is saved successfully at \(fileLocation).")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }
            
            VStack(spacing: AppSpacing.md) {
                Button(action: onOpenLocation) {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("Open Location")
                    }
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.primary)
                    .cornerRadius(AppSpacing.cornerRadiusMD)
                }
                
                HStack(spacing: AppSpacing.md) {
                    Button(action: onShare) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(AppSpacing.cornerRadiusMD)
                    }
                    
                    Button(action: onClose) {
                        Text("Close")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppColors.surfaceSecondary)
                            .cornerRadius(AppSpacing.cornerRadiusMD)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cornerRadiusLG)
        .padding(AppSpacing.lg)
        .shadow(color: AppColors.shadowHeavy.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        SaveSuccessModalView(
            fileName: "Document_annotated.pdf",
            fileLocation: "/Documents/PDFs",
            onOpenLocation: {},
            onShare: {},
            onClose: {}
        )
    }
}
