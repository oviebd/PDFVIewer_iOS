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
    @State private var showMultiDeleteConfirmation = false

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
                
                // Toast Message Overlay
                if let message = viewModel.toastMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.8))
                                    .shadow(radius: 4)
                            )
                            .padding(.bottom, viewModel.isMultiSelectMode ? 100 : 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .frame(maxWidth: .infinity)
                    .animation(.spring(), value: viewModel.toastMessage)
                    .zIndex(100)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.white.ignoresSafeArea())
            .navigationDestination(for: PDFNavigationRoute.self) { route in
                switch route {
                case let .viewer(pdf):
                    PDFViewerView(pdfFile: pdf)
                }
            }
            .toolbar {
                if viewModel.isMultiSelectMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            viewModel.exitMultiSelectMode()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(viewModel.selectedPDFKeys.count == viewModel.visiblePdfModels.count ? "Deselect All" : "Select All") {
                            if viewModel.selectedPDFKeys.count == viewModel.visiblePdfModels.count {
                                viewModel.deselectAll()
                            } else {
                                viewModel.selectAll()
                            }
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showFilePicker.toggle() }) {
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerRepresentable(mode: .file) { [weak viewModel] urls in
                    viewModel?.importPDFsAndForget(urls: urls)
                }
            }
            .sheet(isPresented: $viewModel.isShowingImportProgress) {
                if let importVM = viewModel.importViewModel {
                    PDFImportView(viewModel: importVM)
                }
            }
            .onAppear {
                viewModel.onViewAppear()
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
                            if viewModel.isMultiSelectMode {
                                viewModel.moveSelectedPDFs(to: nil)
                            } else if let pdf = pdfToMove {
                                viewModel.movePDF(pdf, to: nil)
                            }
                            showMoveToFolderSheet = false
                        }
                        ForEach(viewModel.folders) { folder in
                            Button(folder.title) {
                                if viewModel.isMultiSelectMode {
                                    viewModel.moveSelectedPDFs(to: folder)
                                } else if let pdf = pdfToMove {
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
            .safeAreaInset(edge: .bottom) {
                if viewModel.isMultiSelectMode {
                    VStack(spacing: 0) {
                        Divider()
                        HStack {
                            Button(role: .destructive) {
                                showMultiDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .disabled(viewModel.selectedPDFKeys.isEmpty)
                            
                            Spacer()
                            
                            Button {
                                showMoveToFolderSheet = true
                            } label: {
                                Label("Move", systemImage: "folder.badge.plus")
                            }
                            .disabled(viewModel.selectedPDFKeys.isEmpty)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .alert("Delete Selected PDFs?", isPresented: $showMultiDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteSelectedPDFs()
                }
            } message: {
                Text("Are you sure you want to delete \(viewModel.selectedPDFKeys.count) selected PDFs? This action cannot be undone.")
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
                                },
                                onToggleFavorite: {
                                    viewModel.toggleFavorite(for: pdf)
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







