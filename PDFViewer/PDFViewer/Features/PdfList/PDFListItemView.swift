//
//  PDFListItemView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 12/5/25.
//

import SwiftUI

struct PDFListItemView: View {
    let pdf: PDFModelData
    let isMultiSelectMode: Bool
    let isSelected: Bool
    let toggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if isMultiSelectMode {
                Image(systemName: isSelected ? AppImages.checkCircle : AppImages.circle)
                    .font(AppFonts.selectionIcon)
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.inactive)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            // Thumbnail with enhanced shadow and border
            ZStack {
                if let image = pdf.thumbImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: AppColors.thumbnailGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: AppImages.document)
                            .font(AppFonts.iconLarge)
                            .foregroundColor(AppColors.placeholder)
                    }
                }
            }
            .frame(width: AppSpacing.thumbnailWidth, height: AppSpacing.thumbnailHeight)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusMD)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.separator.opacity(0.3), AppColors.separator.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: AppSpacing.borderThin
                    )
            )
            .shadow(color: AppColors.shadowMedium, radius: AppSpacing.shadowRadiusMedium, x: 0, y: 3)

            // Info Section
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(pdf.title ?? AppStrings.PDFInfo.untitledDocument)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // Author and page count
                HStack(spacing: AppSpacing.xxs) {
                    if let author = pdf.author, author != AppStrings.PDFInfo.unknownAuthor {
                        Text(author)
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                        
                        Text("•")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Text(AppStrings.PDFInfo.pageCount(pdf.totalPageCount))
                        .font(AppFonts.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                // Last opened time
                if let lastOpened = pdf.lastOpenTime {
                    Text("\(AppStrings.PDFInfo.opened) \(lastOpened.timeAgoDisplay())")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            Spacer()

            // Favorite Button
            Button(action: toggleFavorite) {
                Image(systemName: pdf.isFavorite ? AppImages.heartFill : AppImages.heart)
                    .font(AppFonts.favoriteIcon)
                    .foregroundColor(pdf.isFavorite ? AppColors.favorite : AppColors.inactive)
                    .padding(AppSpacing.xs)
                    .background(AppColors.buttonBackground)
                    .clipShape(Circle())
                    .shadow(color: AppColors.shadowLight, radius: AppSpacing.shadowRadiusLight, x: 0, y: 2)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, AppSpacing.xs)
        .background(Color.clear)
    }
}


extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
    


#Preview {
    PDFListItemView(
        pdf: samplePDFModelData,
        isMultiSelectMode: false,
        isSelected: false,
        toggleFavorite: {}
    )
}

