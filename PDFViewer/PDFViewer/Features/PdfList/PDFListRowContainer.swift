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

    var body: some View {
        PDFListItemView(
            pdf: pdf,
            toggleFavorite: { viewModel.toggleFavorite(for: pdf) }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(pdf)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.white)
        .contextMenu {
            Button {
                onMove(pdf)
            } label: {
                Label("Move to Folder", systemImage: "folder.badge.plus")
            }
            
            Button(role: .destructive) {
                onDelete(pdf)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
