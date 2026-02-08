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
            HStack(spacing: AppSpacing.sm) {
                // All filter
                FilterPillWithCount(
                    title: AppStrings.Filters.all,
                    count: viewModel.allPdfModels.count,
                    color: AppColors.filterAll,
                    isSelected: currentSelection == .all,
                    action: { onSelect(.all) }
                )
                
                // Favorites filter
                FilterPillWithCount(
                    title: AppStrings.Filters.favorites,
                    count: viewModel.allPdfModels.filter { $0.isFavorite }.count,
                    color: AppColors.filterFavorite,
                    isSelected: currentSelection == .favorite,
                    action: { onSelect(.favorite) }
                )
                
                // Recent filter
                FilterPillWithCount(
                    title: AppStrings.Filters.recent,
                    count: viewModel.allPdfModels.count,
                    color: AppColors.filterRecent,
                    isSelected: currentSelection == .recent,
                    action: { onSelect(.recent) }
                )
                
                // Custom folders
                ForEach(Array(folders.enumerated()), id: \.element.id) { index, folder in
                    FilterPillWithCount(
                        title: folder.title,
                        count: viewModel.allPdfModels.filter { folder.pdfIds.contains($0.key) }.count,
                        color: AppColors.folderColor(for: index),
                        isSelected: currentSelection == .folder(folder),
                        action: { onSelect(.folder(folder)) }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete(folder)
                        } label: {
                            Label(AppStrings.Actions.delete, systemImage: AppImages.trash)
                        }
                    }
                }
                
                // Add folder button
                Button(action: onCreate) {
                    VStack(spacing: AppSpacing.xxs) {
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: AppImages.addCircle)
                                .font(AppFonts.iconSmall)
                            Text(AppStrings.Filters.new)
                                .font(AppFonts.iconSmall)
                        }
                        .foregroundColor(AppColors.inactive)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            Capsule()
                                .stroke(AppColors.separator, lineWidth: AppSpacing.borderNormal)
                        )
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
        .background(AppColors.background)
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
                .foregroundColor(isSelected ? AppColors.onPrimary : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? color : AppColors.background)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : color.opacity(0.5), lineWidth: AppSpacing.borderThick)
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
