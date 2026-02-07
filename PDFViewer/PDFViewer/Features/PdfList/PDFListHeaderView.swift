//
//  PDFListHeaderView.swift
//  PDFViewer
//
//  Created by Antigravity
//

import SwiftUI

struct PDFListHeaderView: View {
    @ObservedObject var viewModel: PDFListViewModel
    var onCreateFolder: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            FilterSegmentView(
                folders: viewModel.folders,
                currentSelection: viewModel.currentSelection,
                onCreate: onCreateFolder,
                onSelect: { viewModel.updateSelection($0) },
                onDelete: { viewModel.deleteFolder($0) },
                viewModel: viewModel
            )
            Divider()
        }
        .listRowInsets(EdgeInsets())
        .background(Color.white)
    }
}
