//
//  PDFListView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/4/25.
//

import SwiftUI

enum PDFNavigationRoute: Hashable {
    case viewer(PDFModelData)
}

struct PDFListView: View {
    @StateObject private var viewModel: PDFListViewModel
    @State private var showFilePicker = false
    @State private var navigationPath = NavigationPath()

    init() {
        let store = try? PDFLocalDataStore()
        let repo = PDFLocalRepositoryImpl(store: store!)
        _viewModel = StateObject(wrappedValue: PDFListViewModel(repository: repo))
    }

    @State private var showCreateFolderAlert = false
    @State private var newFolderName = ""
    @State private var pdfToMove: PDFModelData?
    @State private var showMoveToFolderSheet = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        PDFListContentView(
                            viewModel: viewModel,
                            onSelect: { pdf in
                                navigationPath.append(PDFNavigationRoute.viewer(pdf))
                            },
                            onMove: { pdf in
                                pdfToMove = pdf
                                showMoveToFolderSheet = true
                            },
                            onCreateFolder: {
                                newFolderName = ""
                                showCreateFolderAlert = true
                            }
                        )
                    }
                }
                .navigationTitle("Library")
                .navigationBarTitleDisplayMode(.large)
                
                // Floating Action Button
                if let lastOpened = viewModel.lastOpenedPdf {
                    Button(action: {
                        navigationPath.append(PDFNavigationRoute.viewer(lastOpened))
                    }) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationDestination(for: PDFNavigationRoute.self) { route in
                switch route {
                case let .viewer(pdf):
                    PDFViewerView(pdfFile: pdf)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showFilePicker.toggle() }) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Search functionality - placeholder
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerRepresentable(mode: .file) { [weak viewModel] urls in
                    viewModel?.importPDFsAndForget(urls: urls)
                }
            }
            .onAppear {
                viewModel.loadPDFsAndForget()
            }
            .alert("New Folder", isPresented: $showCreateFolderAlert) {
                TextField("Folder Name", text: $newFolderName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    if !newFolderName.isEmpty {
                        viewModel.createFolder(title: newFolderName)
                    }
                }
            }
            .sheet(isPresented: $showMoveToFolderSheet) {
                NavigationStack {
                    List {
                        Button("No Folder") {
                            if let pdf = pdfToMove {
                                viewModel.movePDF(pdf, to: nil)
                            }
                            showMoveToFolderSheet = false
                        }
                        ForEach(viewModel.folders) { folder in
                            Button(folder.title) {
                                if let pdf = pdfToMove {
                                    viewModel.movePDF(pdf, to: folder)
                                }
                                showMoveToFolderSheet = false
                            }
                        }
                    }
                    .navigationTitle("Move to Folder")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showMoveToFolderSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}

#Preview {
    NavigationStack {
        PDFListView()
    }
}

struct PDFListContentView: View {
    @ObservedObject var viewModel: PDFListViewModel
    var onSelect: (PDFModelData) -> Void
    var onMove: (PDFModelData) -> Void
    var onCreateFolder: () -> Void
    
    @State private var pdfToDelete: PDFModelData?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if viewModel.allPdfModels.isEmpty {
                PDFListEmptyView(
                    viewModel: viewModel,
                    onCreateFolder: onCreateFolder
                )
            } else {
                List {
                    PDFListHeaderView(
                        viewModel: viewModel,
                        onCreateFolder: onCreateFolder
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.white)

                    ForEach(viewModel.visiblePdfModels, id: \.id) { pdf in
                        PDFListRowContainer(
                                pdf: pdf,
                                viewModel: viewModel,
                                onSelect: onSelect,
                                onMove: onMove,
                                onDelete: { pdf in
                                    pdfToDelete = pdf
                                    showDeleteConfirmation = true
                                }
                            )
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.white)
            }
        }
        .alert("Delete PDF?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                pdfToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let pdf = pdfToDelete,
                   let index = viewModel.visiblePdfModels.firstIndex(where: { $0.key == pdf.key }) {
                    viewModel.deletePdf(indexSet: IndexSet(integer: index))
                }
                pdfToDelete = nil
            }
        } message: {
            if let pdf = pdfToDelete {
                Text("Are you sure you want to delete '\(pdf.title ?? "this PDF")'? This action cannot be undone.")
            }
        }
    }
}







