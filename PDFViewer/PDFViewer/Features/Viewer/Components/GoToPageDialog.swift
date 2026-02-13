//
//  GoToPageDialog.swift
//  PDFViewer
//
//  Created by Antigravity on 13/2/26.
//

import SwiftUI

struct GoToPageDialog: View {
    @Binding var isPresented: Bool
    let totalPages: Int
    let onGo: (Int) -> Void

    @State private var inputPage: String = ""
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }

            // Dialog Card
            VStack(spacing: AppSpacing.lg) {
                Text("Go to Page")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    TextField("Page number", text: $inputPage)
                        .keyboardType(.numberPad)
                        .padding(AppSpacing.md)
                        .background(AppColors.surfaceSecondary)
                        .cornerRadius(AppSpacing.cornerRadiusSM)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSM)
                                .stroke(errorMessage != nil ? AppColors.error : AppColors.separator, lineWidth: 1)
                        )
                        .foregroundColor(AppColors.textPrimary)

                    HStack {
                        Text("Total pages: \(totalPages)")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Spacer()
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(AppFonts.caption)
                                .foregroundColor(AppColors.error)
                        }
                    }
                }

                HStack(spacing: AppSpacing.md) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(AppFonts.footnote)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.surfaceSecondary)
                            .cornerRadius(AppSpacing.cornerRadiusSM)
                    }

                    Button(action: validateAndGo) {
                        Text("Go")
                            .font(AppFonts.footnote)
                            .foregroundColor(AppColors.onPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.primary)
                            .cornerRadius(AppSpacing.cornerRadiusSM)
                    }
                }
            }
            .padding(AppSpacing.xl)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cornerRadiusLG)
            .shadow(color: AppColors.shadowHeavy, radius: 10)
            .padding(.horizontal, AppSpacing.xxxl)
        }
    }

    private func validateAndGo() {
        guard let page = Int(inputPage) else {
            errorMessage = "Please enter a valid number"
            return
        }

        if page < 1 || page > totalPages {
            errorMessage = "Page range: 1 to \(totalPages)"
        } else {
            errorMessage = nil
            onGo(page)
            isPresented = false
        }
    }
}

#Preview {
    GoToPageDialog(isPresented: .constant(true), totalPages: 10) { page in
        print("Go to page \(page)")
    }
}
