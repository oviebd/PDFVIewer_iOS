//
//  PDFListView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/4/25.
//

import SwiftUI

struct PDFListView: View {
    //  @EnvironmentObject var drawingToolManager: DrawingToolManager
    @StateObject private var viewModel: PDFListViewModel
    @State private var showFilePicker = false

    init() {
        let store = try? PDFLocalDataStore()
        let repo = PDFLocalRepositoryImpl(store: store!)
        _viewModel = StateObject(wrappedValue: PDFListViewModel(repository: repo))
    }

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.pdfModels, id: \.id) { pdf in

                            NavigationLink(value: pdf) {
                                PDFListItemView(
                                    pdf: pdf,
                                    toggleFavorite: { viewModel.toggleFavorite(for: pdf) }
                                )
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.deletePdf(indexSet: indexSet)
                        }
                    }
                  // .listStyle(.plain)
                }
            }
            .navigationTitle("PDF Files")
            .navigationDestination(for: PDFModelData.self) { selectedItem in
                PDFViewerView(pdfFile: selectedItem)
            }
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
                // drawingToolManager.toolColors[.pen] = .green
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
