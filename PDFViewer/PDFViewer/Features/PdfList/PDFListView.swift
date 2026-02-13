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
    @StateObject private var subscriptionVM = SubscriptionPlanViewModel()
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
                                if subscriptionVM.canCreateMoreFolders(currentCount: viewModel.folders.count) {
                                    newFolderName = ""
                                    showCreateFolderAlert = true
                                } else {
                                    subscriptionVM.showPremiumAlert(message: subscriptionVM.folderLimitWarning(currentCount: viewModel.folders.count) ?? "")
                                }
                            },
                            onImport: {
                                if subscriptionVM.canImportMorePDFs(currentCount: viewModel.allPdfModels.count) {
                                    showFilePicker = true
                                } else {
                                    subscriptionVM.showPremiumAlert(message: subscriptionVM.pdfImportLimitWarning(currentCount: viewModel.allPdfModels.count) ?? "")
                                }
                            },
                            onFavoriteRestricted: {
                                subscriptionVM.showPremiumAlert(message: subscriptionVM.favoriteRestrictedMessage)
                            }
                        )
                    }
                }
              
                
                // Floating Action Button
                if let lastOpened = viewModel.lastOpenedPdf {
                    Button(action: {
                        navigationPath.append(PDFNavigationRoute.viewer(lastOpened))
                    }) {
                        Image(systemName: AppImages.book)
                            .font(AppFonts.iconLarge)
                            .foregroundColor(AppColors.onPrimary)
                            .frame(width: AppSpacing.fabSize, height: AppSpacing.fabSize)
                            .background(
                                Circle()
                                    .fill(LinearGradient(
                                        colors: AppColors.primaryGradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .shadow(color: AppColors.shadowHeavy, radius: AppSpacing.shadowRadiusMedium, x: 0, y: 5)
                            )
                    }
                    .padding(.trailing, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxl)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Toast Message Overlay
                if let message = viewModel.toastMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.onPrimary)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                Capsule()
                                    .fill(AppColors.toastBackground)
                                    .shadow(radius: AppSpacing.shadowRadiusLight)
                            )
                            .padding(.bottom, viewModel.isMultiSelectMode ? 100 : AppSpacing.xxxl)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .frame(maxWidth: .infinity)
                    .animation(.spring(), value: viewModel.toastMessage)
                    .zIndex(100)
                }
            }
            .navigationTitle(AppStrings.Navigation.library)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: AppStrings.PDFList.searchPrompt)
            .background(AppColors.background.ignoresSafeArea())
            .navigationDestination(for: PDFNavigationRoute.self) { route in
                switch route {
                case let .viewer(pdf):
                    PDFViewerView(pdfFile: pdf)
                }
            }
            .toolbar {
                if viewModel.isMultiSelectMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(AppStrings.Navigation.cancel) {
                            viewModel.exitMultiSelectMode()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(viewModel.selectedPDFKeys.count == viewModel.visiblePdfModels.count ? AppStrings.PDFList.deselectAll : AppStrings.PDFList.selectAll) {
                            if viewModel.selectedPDFKeys.count == viewModel.visiblePdfModels.count {
                                viewModel.deselectAll()
                            } else {
                                viewModel.selectAll()
                            }
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { 
                            if subscriptionVM.canImportMorePDFs(currentCount: viewModel.allPdfModels.count) {
                                showFilePicker.toggle()
                            } else {
                                subscriptionVM.showPremiumAlert(message: subscriptionVM.pdfImportLimitWarning(currentCount: viewModel.allPdfModels.count) ?? "")
                            }
                        }) {
                            Image(systemName: AppImages.download)
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
            .alert(AppStrings.Folders.newFolderTitle, isPresented: $showCreateFolderAlert) {
                TextField(AppStrings.Folders.folderNamePlaceholder, text: $newFolderName)
                Button(AppStrings.Navigation.cancel, role: .cancel) { }
                Button(AppStrings.Navigation.create) {
                    if !newFolderName.isEmpty {
                        viewModel.createFolder(title: newFolderName)
                    }
                }
            }
            .sheet(isPresented: $showMoveToFolderSheet) {
                NavigationStack {
                    List {
                        Button(AppStrings.Folders.noFolder) {
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
                    .navigationTitle(AppStrings.Folders.moveToFolder)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(AppStrings.Navigation.close) { showMoveToFolderSheet = false }
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
                                Label(AppStrings.Actions.delete, systemImage: AppImages.trash)
                            }
                            .disabled(viewModel.selectedPDFKeys.isEmpty)
                            
                            Spacer()
                            
                            Button {
                                showMoveToFolderSheet = true
                            } label: {
                                Label(AppStrings.Actions.move, systemImage: AppImages.folderAdd)
                            }
                            .disabled(viewModel.selectedPDFKeys.isEmpty)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .alert(AppStrings.Actions.deleteSelectedPDFs, isPresented: $showMultiDeleteConfirmation) {
                Button(AppStrings.Navigation.cancel, role: .cancel) { }
                Button(AppStrings.Actions.delete, role: .destructive) {
                    viewModel.deleteSelectedPDFs()
                }
            } message: {
                Text(AppStrings.Confirmation.deleteMultipleConfirmation(count: viewModel.selectedPDFKeys.count))
            }
            .premiumFeatureAlert(
                isPresented: $subscriptionVM.isShowingPremiumAlert,
                title: subscriptionVM.premiumAlertTitle,
                message: subscriptionVM.premiumAlertMessage
            ) {
                subscriptionVM.isShowingPaywall = true
            }
            .fullScreenCover(isPresented: $subscriptionVM.isShowingPaywall) {
                PlanPage()
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
    var onImport: () -> Void
    var onFavoriteRestricted: () -> Void
    
    @State private var pdfToDelete: PDFModelData?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if viewModel.visiblePdfModels.isEmpty {
                PDFListEmptyView(
                    viewModel: viewModel,
                    onCreateFolder: onCreateFolder,
                    onImport: onImport
                )
            } else {
                List {
                    PDFListHeaderView(
                        viewModel: viewModel,
                        onCreateFolder: onCreateFolder
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(AppColors.background)

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
                                    if SubscriptionManager.shared.isFavoriteAllowed {
                                        viewModel.toggleFavorite(for: pdf)
                                    } else {
                                        // Since we can't easily access subscriptionVM here or pass it down,
                                        // we can either add a closure to PDFListContentView or use the singleton
                                        // But for the alert, it's better to bubble it up to PDFListView
                                        // I'll add onFavoriteRestricted closure to PDFListContentView
                                        onFavoriteRestricted()
                                    }
                                }
                            )
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppColors.background)
            }
        }
        .alert(AppStrings.Actions.deletePDF, isPresented: $showDeleteConfirmation) {
            Button(AppStrings.Navigation.cancel, role: .cancel) {
                pdfToDelete = nil
            }
            Button(AppStrings.Actions.delete, role: .destructive) {
                if let pdf = pdfToDelete,
                   let index = viewModel.visiblePdfModels.firstIndex(where: { $0.key == pdf.key }) {
                    viewModel.deletePdf(indexSet: IndexSet(integer: index))
                }
                pdfToDelete = nil
            }
        } message: {
            if let pdf = pdfToDelete {
                Text(AppStrings.Confirmation.deleteConfirmation(title: pdf.title))
            }
        }
    }
}







