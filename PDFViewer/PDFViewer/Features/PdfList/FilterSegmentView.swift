//
//  FilterSegmentView.swift
//  PDFViewer
//
//  Created by Habibur Rahman
//

import SwiftUI

struct FilterSegmentView: View {
    let folders: [FolderModelData]
    let currentSelection: PDFListSelection
    let onCreate: () -> Void
    let onSelect: (PDFListSelection) -> Void
    let onDelete: (FolderModelData) -> Void
    @ObservedObject var viewModel: PDFListViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All filter
                FilterPillWithCount(
                    title: "All",
                    count: viewModel.allPdfModels.count,
                    color: .blue,
                    isSelected: currentSelection == .all,
                    action: { onSelect(.all) }
                )
                
                // Favorites filter
                FilterPillWithCount(
                    title: "Favorites",
                    count: viewModel.allPdfModels.filter { $0.isFavorite }.count,
                    color: .red,
                    isSelected: currentSelection == .favorite,
                    action: { onSelect(.favorite) }
                )
                
                // Recent filter
                FilterPillWithCount(
                    title: "Recent",
                    count: viewModel.allPdfModels.count,
                    color: .green,
                    isSelected: currentSelection == .recent,
                    action: { onSelect(.recent) }
                )
                
                // Custom folders
                ForEach(Array(folders.enumerated()), id: \.element.id) { index, folder in
                    FilterPillWithCount(
                        title: folder.title,
                        count: viewModel.allPdfModels.filter { folder.pdfIds.contains($0.key) }.count,
                        color: folderColor(for: index),
                        isSelected: currentSelection == .folder(folder),
                        action: { onSelect(.folder(folder)) }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete(folder)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                // Add folder button
                Button(action: onCreate) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("New")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color(.systemGray))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }
    
    private func folderColor(for index: Int) -> Color {
        let colors: [Color] = [.purple, .orange, .teal, .pink, .indigo, .cyan]
        return colors[index % colors.count]
    }
}

struct FilterPillWithCount: View {
    let title: String
    let count: Int
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(title) (\(count))")
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : Color(.label))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.white)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : color.opacity(0.5), lineWidth: 1.5)
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    FilterSegmentView(
        folders: [],
        currentSelection: .all,
        onCreate: {},
        onSelect: { _ in },
        onDelete: { _ in },
        viewModel: PDFListViewModel(repository: PDFLocalRepositoryImpl(store: try! PDFLocalDataStore()))
    )
}
