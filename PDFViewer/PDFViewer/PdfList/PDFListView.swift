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
        let repo = PDFLocalRepositoryImpl(store: store!)
        _viewModel = StateObject(wrappedValue: PDFListViewModel(repository: repo))
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Button("Select Files") {
                        showFilePicker.toggle()
                    }
                    Button("Load Cached PDFs") {
                        viewModel.loadPDFsAndForget()
                    }
                }
                .padding()

                if viewModel.isLoading {
                    ProgressView()
                }

                List(viewModel.pdfModels, id: \.id) { pdf in
                    NavigationLink(destination: PDFViewerView(pdfFile: pdf)) {
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
                        }
                    }
                }
                .navigationTitle("PDF Files")
            }
            .onAppear{
                viewModel.loadPDFsAndForget()
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerRepresentable(mode: .file) { urls in
                    viewModel.importPDFsAndForget(urls: urls)

                }
            }
        }
    }
}

#Preview {
    PDFListView()
}
