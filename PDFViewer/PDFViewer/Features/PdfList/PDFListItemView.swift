//
//  PDFListItemView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 12/5/25.
//

import SwiftUI

struct PDFListItemView: View {
    let pdf: PDFModelData
    let toggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail with enhanced shadow and border
            ZStack {
                if let image = pdf.thumbImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "doc.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(.systemGray3))
                    }
                }
            }
            .frame(width: 55, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        LinearGradient(
                            colors: [Color(.separator).opacity(0.3), Color(.separator).opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)

            // Info Section
            VStack(alignment: .leading, spacing: 4) {
                Text(pdf.title ?? "Untitled Document")
                    .font(.headline)
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // Author and page count
                HStack(spacing: 4) {
                    if let author = pdf.author, author != "Unknown" {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                            .lineLimit(1)
                        
                        Text("•")
                            .font(.subheadline)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                    
                    Text("\(pdf.totalPageCount) Pages")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                // Last opened time
                if let lastOpened = pdf.lastOpenTime {
                    Text("Opened \(lastOpened.timeAgoDisplay())")
                        .font(.caption)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            Spacer()

            // Favorite Button
            Button(action: toggleFavorite) {
                Image(systemName: pdf.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(pdf.isFavorite ? Color(.systemRed) : Color(.systemGray3))
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
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
        toggleFavorite: {}
    )
}

