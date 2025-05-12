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

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.pdfModels, id: \.id) { pdf in
                            PDFListItemView(
                                pdf: pdf,
                                toggleFavorite: { viewModel.toggleFavorite(for: pdf) }
                            )
                        }
                        .onDelete { indexSet in
                            viewModel.deletePdf(indexSet: indexSet)
                           
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("PDF Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ImportButton {
                        showFilePicker.toggle()
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerRepresentable(mode: .file) { urls in
                    viewModel.importPDFsAndForget(urls: urls)
                }
            }
            .onAppear {
                viewModel.loadPDFsAndForget()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PDFListView()
    }
}

struct ImportButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(5)
                .background(Circle().fill(Color.blue))
                .shadow(radius: 2)
        }
        .accessibilityLabel("Import PDF Files")
    }
}

struct PDFListItemView: View {
    let pdf: PDFModelData
    let toggleFavorite: () -> Void

    var body: some View {
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

                Spacer()

                Button(action: toggleFavorite) {
                    Image(systemName: pdf.isFavorite ? "star.fill" : "star")
                        .foregroundColor(pdf.isFavorite ? .yellow : .gray)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(.vertical, 5)
        }
    }
}
