//
//  PDFListView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/4/25.
//

import SwiftUI

enum PDFSortOption: String, CaseIterable, Identifiable {
    case all = "All"
    case favorite = "Favorite"
    case recent = "Recent"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .all: return "tray.full"
        case .favorite: return "heart.fill"
        case .recent: return "clock"
        }
    }
}

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

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        PDFListContentView(viewModel: viewModel, onSelect: { pdf in
                            navigationPath.append(PDFNavigationRoute.viewer(pdf))
                        })
                    }
                }
                .navigationTitle(viewModel.selectedSortOption.rawValue)

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

                            Menu {
                                ForEach(PDFSortOption.allCases) { option in
                                    Button {
                                        viewModel.updateSortOption(option)
                                    } label: {
                                        Label(option.rawValue, systemImage: option.iconName)
                                    }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease")
                            }
                            .accessibilityLabel("Sort PDFs")
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
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            List {
                ForEach(viewModel.visiblePdfModels, id: \.id) { pdf in
                    Button(action: {
                        onSelect(pdf)
                    }) {
                        PDFListItemView(
                            pdf: pdf,
                            toggleFavorite: { viewModel.toggleFavorite(for: pdf) }
                        )
                    }
                }
                .onDelete(perform: viewModel.deletePdf)
            }
            .listStyle(.plain)
        }
    }
}

struct PDFSortFilterView: View {
    @Binding var selectedOption: PDFSortOption
    var onSelect: (PDFSortOption) -> Void

    var body: some View {
        Menu {
            ForEach(PDFSortOption.allCases) { option in
                Button {
                    onSelect(option)
                } label: {
                    Text(option.rawValue)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedOption.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.down")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}
