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
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(isSelected ? Color.blue.opacity(0.1) : Color.white)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !viewModel.isMultiSelectMode {
                Button(role: .destructive) {
                    onDelete(pdf)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                
                Button {
                    onMove(pdf)
                } label: {
                    Label("Move", systemImage: "folder.badge.plus")
                }
                .tint(Color(.systemBlue))
            }
        }
    }
}
