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
            ZStack {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 0) {
                            FolderRowView(
                                folders: viewModel.folders,
                                currentSelection: viewModel.currentSelection,
                                onCreate: {
                                    newFolderName = ""
                                    showCreateFolderAlert = true
                                },
                                onSelect: { viewModel.updateSelection($0) },
                                onDelete: { viewModel.deleteFolder($0) }
                            )

                            Color.gray.opacity(0.05)
                                .frame(height: 1)

                            PDFListContentView(viewModel: viewModel, onSelect: { pdf in
                                navigationPath.append(PDFNavigationRoute.viewer(pdf))
                            }, onMove: { pdf in
                                pdfToMove = pdf
                                showMoveToFolderSheet = true
                            })
                            .background(Color(red: 0.98, green: 0.98, blue: 1.0))
                        }
                    }
                }
                .navigationTitle(viewModel.currentSelection.title)

                .navigationDestination(for: PDFNavigationRoute.self) { route in
                    switch route {
                    case let .viewer(pdf):
                        PDFViewerView(pdfFile: pdf)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            ImportButton {
                                showFilePicker.toggle()
                            }
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

                // Floating Book Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // Add your action here
                            if let firstPDF = viewModel.getRecentFiles().first {
                                navigationPath.append(PDFNavigationRoute.viewer(firstPDF))
                            }
                        }) {
                            Image(systemName: "book")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding()
                    }
                }
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
            Image(systemName: "square.and.arrow.down")
                .font(.subheadline)
        }
    }
}

struct PDFListContentView: View {
    @ObservedObject var viewModel: PDFListViewModel
    var onSelect: (PDFModelData) -> Void
    var onMove: (PDFModelData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.visiblePdfModels, id: \.id) { pdf in
                        Button(action: {
                            onSelect(pdf)
                        }) {
                            PDFListItemView(
                                pdf: pdf,
                                toggleFavorite: { viewModel.toggleFavorite(for: pdf) }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contextMenu {
                            Button {
                                onMove(pdf)
                            } label: {
                                Label("Move to Folder", systemImage: "folder.badge.plus")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                onMove(pdf)
                            } label: {
                                Label("Move", systemImage: "folder.badge.plus")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: viewModel.deletePdf)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
}

struct FolderRowView: View {
    let folders: [FolderModelData]
    let currentSelection: PDFListSelection
    let onCreate: () -> Void
    let onSelect: (PDFListSelection) -> Void
    let onDelete: (FolderModelData) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // "All" folder
                FolderItem(
                    title: "All",
                    icon: "tray.full.fill",
                    color: .blue,
                    isSelected: currentSelection == .all,
                    action: { onSelect(.all) }
                )

                // "Favorite" folder
                FolderItem(
                    title: "Favorite",
                    icon: "heart.fill",
                    color: .red,
                    isSelected: currentSelection == .favorite,
                    action: { onSelect(.favorite) }
                )

                // "Recent" folder
                FolderItem(
                    title: "Recent",
                    icon: "clock.fill",
                    color: .green,
                    isSelected: currentSelection == .recent,
                    action: { onSelect(.recent) }
                )

                ForEach(Array(folders.enumerated()), id: \.element.id) { index, folder in
                    FolderItem(
                        title: folder.title,
                        icon: "folder.fill",
                        color: folderColor(for: index),
                        isSelected: currentSelection == .folder(folder),
                        action: { onSelect(.folder(folder)) }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete(folder)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                // Add Button
                Button(action: onCreate) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 52, height: 52)
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        Text("New")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(red: 0.98, green: 0.98, blue: 1.0))
    }

    private func folderColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .purple, .orange, .teal, .pink, .indigo]
        return colors[index % colors.count]
    }
}

struct FolderItem: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(color)
                            .frame(width: 52, height: 52)
                            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 52, height: 52)

                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(color)
                    }
                }

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? color : .primary.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(width: 64)
        }
    }
}
