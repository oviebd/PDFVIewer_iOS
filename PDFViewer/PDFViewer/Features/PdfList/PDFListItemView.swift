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
        HStack {
            if let image = pdf.thumbImage {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 50, height: 70)
                    .cornerRadius(5)
            } else {
                Image(systemName: "doc.text")
                    .resizable()
                    .frame(width: 50, height: 70)
                    .cornerRadius(5)
            }

            VStack(alignment: .leading) {
                Text(pdf.title ?? "Untitled")
                    .font(.headline)
                Text("Author: \(pdf.author ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: toggleFavorite) {
                Image(systemName: pdf.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(pdf.isFavorite ? .red : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 5)
    }
    
    
}

#Preview {
    PDFListItemView(pdf:samplePDFModelData, toggleFavorite: {
        
    })
}
