//
//  PDFListEmptyView.swift
//  PDFViewer
//
//  Created by Antigravity
//

import SwiftUI

struct PDFListEmptyView: View {
    @ObservedObject var viewModel: PDFListViewModel
    var onCreateFolder: () -> Void
    var onImport: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            PDFListHeaderView(
                viewModel: viewModel,
                onCreateFolder: onCreateFolder
            )
            Divider()
            EmptyStateView(onImport: {
                onImport()
            })
            Spacer()
        }
        .background(AppColors.background)
    }
}
