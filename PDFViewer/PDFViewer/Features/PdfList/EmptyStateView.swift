//
//  EmptyStateView.swift
//  PDFViewer
//
//  Created by Habibur Rahman
//

import SwiftUI

struct EmptyStateView: View {
    let onImport: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Icon
            Image(systemName: "doc.fill")
                .font(.system(size: 64))
                .foregroundColor(Color(.systemGray3))
            
            // Title and subtitle
            VStack(spacing: 8) {
                Text("No PDFs yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                
                Text("Import your first PDF to start reading")
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
            
            // Import button
            Button(action: onImport) {
                Text("Import PDF")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBlue))
                    )
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    EmptyStateView(onImport: {})
}
