//
//  PDFListRowContainer.swift
//  PDFViewer
//
//  Created by Antigravity
//

import SwiftUI

struct PDFListRowContainer: View {
    let pdf: PDFModelData
    @ObservedObject var viewModel: PDFListViewModel
    var onSelect: (PDFModelData) -> Void
    var onMove: (PDFModelData) -> Void
    var onDelete: (PDFModelData) -> Void
    var onToggleFavorite: () -> Void

    private var isSelected: Bool {
        viewModel.selectedPDFKeys.contains(pdf.key)
    }

    var body: some View {
        PDFListItemView(
            pdf: pdf,
            isMultiSelectMode: viewModel.isMultiSelectMode,
            isSelected: isSelected,
            toggleFavorite: onToggleFavorite
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.isMultiSelectMode {
                viewModel.toggleSelection(for: pdf.key)
            } else {
                onSelect(pdf)
            }
        }
        .onLongPressGesture {
            if !viewModel.isMultiSelectMode {
                viewModel.enterMultiSelectMode(with: pdf.key)
            }
        }
        .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
        .listRowBackground(isSelected ? AppColors.primary.opacity(0.1) : AppColors.background)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !viewModel.isMultiSelectMode {
                Button(role: .destructive) {
                    onDelete(pdf)
                } label: {
                    Label(AppStrings.Actions.delete, systemImage: AppImages.trash)
                }
                
                Button {
                    onMove(pdf)
                } label: {
                    Label(AppStrings.Actions.move, systemImage: AppImages.folderAdd)
                }
                .tint(AppColors.primary)
            }
        }
    }
}
