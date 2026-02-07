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
        HStack(spacing: 16) {
            // Thumbnail with Shadow and Border
            ZStack {
                if let image = pdf.thumbImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: "doc.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
            }
            .frame(width: 60, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)

            // Info Section
            VStack(alignment: .leading, spacing: 6) {
                Text(pdf.title ?? "Untitled Document")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let author = pdf.author, author != "Unknown" {
                        Text(author)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 3, height: 3)
                    }
                    
                    Text("\(pdf.totalPageCount) Pages")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue.opacity(0.8))
                }
                
                if let lastOpened = pdf.lastOpenTime {
                    Text("Opened \(lastOpened.timeAgoDisplay())")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Favorite Button with subtle background
            Button(action: toggleFavorite) {
                Image(systemName: pdf.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(pdf.isFavorite ? .red : .gray.opacity(0.4))
                    .padding(10)
                    .background(pdf.isFavorite ? Color.red.opacity(0.08) : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
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
    PDFListItemView(pdf:samplePDFModelData, toggleFavorite: {
        
    })
}
