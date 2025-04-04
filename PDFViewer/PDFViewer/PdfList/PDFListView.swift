//
//  PDFListView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/4/25.
//

import SwiftUI

struct PDFListView: View {
    @StateObject private var pdfManager = PDFManager()
    @State private var selectedFolderURL: URL?
    @State private var showPicker = false

    var body: some View {
        NavigationView {
            VStack {
                Button("Select Folder") {
                    showPicker.toggle()
                }
                .padding()

                List(pdfManager.pdfFiles) { pdf in
                    NavigationLink(destination: PDFViewerView(pdfUrl: pdf.url)) {
                       // Text(pdf.name)
                        
                        HStack{
                            if let image = pdf.metadata.image {
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
                                Text(pdf.metadata.title)
                                    .font(.headline)
                                Text("Author: \(pdf.metadata.author)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                       

                    }
                }
                .navigationTitle("PDF Files")
            }
            .sheet(isPresented: $showPicker) {
                FolderPickerView { folderURL in
                    self.selectedFolderURL = folderURL
                    pdfManager.fetchPDFFiles(from: folderURL)
                }
            }
        }
    }
}

#Preview {
    PDFListView()
}
