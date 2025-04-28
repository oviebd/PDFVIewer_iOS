//
//  PDFListView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/4/25.
//

import SwiftUI

struct PDFListView: View {
    @StateObject private var viewModel: PDFListViewModel

    @State private var showFilePicker = false

    init() {
        let store = try? PDFLocalDataStore()
        let loader = store.map { PDFLocalDataLoader(store: $0) }
        let repo = loader.map { PDFRepositoryImpl(loader: $0) }
        _viewModel = StateObject(wrappedValue: PDFListViewModel(repository: repo!))
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button("Select Files") {
                        showFilePicker.toggle()
                    }
                    Button("Load Cached PDFs") {
                        viewModel.loadPDFs()
                    }
                }
                .padding()

                if viewModel.isLoading {
                    ProgressView()
                }

                List(viewModel.pdfFiles) { pdf in
                    NavigationLink(destination: PDFViewerView(pdfFile: pdf)) {
                        HStack {
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
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerRepresentable(mode: .file) { urls in
                    viewModel.importPDFs(urls: urls)
                }
            }
        }
    }
}

#Preview {
    PDFListView()
}
