//
//  PDFListViewModel.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 27/4/25.
//

import Combine
import CryptoKit
import Foundation

enum PDFListSelection: Equatable, Hashable {
    case all
    case favorite
    case recent
    case folder(FolderModelData)
    
    var title: String {
        switch self {
        case .all: return "All"
        case .favorite: return "Favorite"
        case .recent: return "Recent"
        case .folder(let folder): return folder.title
        }
    }
    
    var iconName: String {
        switch self {
        case .all: return "tray.full.fill"
        case .favorite: return "heart.fill"
        case .recent: return "clock.fill"
        case .folder: return "folder.fill"
        }
    }
}

final class PDFListViewModel: ObservableObject {
    
    @Published var currentSelection: PDFListSelection = .all
    @Published var allPdfModels: [PDFModelData] = []
    @Published var visiblePdfModels: [PDFModelData] = []
    @Published var folders: [FolderModelData] = []
    
    @Published var importViewModel: PDFImportViewModel?
    @Published var isShowingImportProgress = false
    @Published var searchText: String = ""

    @Published var isMultiSelectMode: Bool = false
    @Published var selectedPDFKeys: Set<String> = []

    private var repository: PDFRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var toastMessage: String?

    init(repository: PDFRepositoryProtocol) {
        self.repository = repository
        loadFolders()
        
        $searchText
            .dropFirst()
            .sink { [weak self] _ in
                self?.applySelection()
            }
            .store(in: &cancellables)
    }

    func loadFolders() {
        repository.retrieveFolders()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] folders in
                self?.folders = folders
            })
            .store(in: &cancellables)
    }

    func createFolder(title: String) {
        let newFolder = FolderModelData(title: title)
        repository.insertFolders(folders: [newFolder])
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] success in
                if success {
                    self?.loadFolders()
                }
            })
            .store(in: &cancellables)
    }

    func renameFolder(_ folder: FolderModelData, newTitle: String) {
        folder.title = newTitle
        updateFolder(folder)
    }

    func updateFolder(_ folder: FolderModelData) {
        folder.updatedAt = Date()
        repository.updateFolder(updatedFolder: folder)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.loadFolders()
            })
            .store(in: &cancellables)
    }

    func deleteFolder(_ folder: FolderModelData) {
        repository.deleteFolder(folderId: folder.id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] success in
                if success {
                if success {
                    if case .folder(let selected) = self?.currentSelection, selected.id == folder.id {
                        self?.currentSelection = .all
                    }
                    self?.loadFolders()
                }
                }
            })
            .store(in: &cancellables)
    }

    func selectFolder(_ folder: FolderModelData?) {
        if let folder = folder {
            currentSelection = .folder(folder)
        } else {
            currentSelection = .all
        }
        applySelection()
    }

    func movePDF(_ pdf: PDFModelData, to folder: FolderModelData?) {
        movePDFs([pdf], to: folder)
    }

    func movePDFs(_ pdfs: [PDFModelData], to folder: FolderModelData?) {
        for pdf in pdfs {
            // Remove from current folder if any
            for f in folders {
                if let index = f.pdfIds.firstIndex(of: pdf.key) {
                    var updatedPdfIds = f.pdfIds
                    updatedPdfIds.remove(at: index)
                    f.pdfIds = updatedPdfIds
                    updateFolder(f)
                }
            }

            // Add to new folder
            if let targetFolder = folder {
                var updatedPdfIds = targetFolder.pdfIds
                if !updatedPdfIds.contains(pdf.key) {
                    updatedPdfIds.append(pdf.key)
                    targetFolder.pdfIds = updatedPdfIds
                    updateFolder(targetFolder)
                }
            }
        }
        
        // Immediate list update
        applySelection()
        
        // Confirmation Toast
        let folderName = folder?.title ?? "No Folder"
        let count = pdfs.count
        toastMessage = count == 1 ? "Moved '\(pdfs[0].title ?? "PDF")' to \(folderName)" : "Moved \(count) items to \(folderName)"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.toastMessage = nil
        }
    }

    private var isLoaded = false

    func onViewAppear() {
        if !isLoaded {
            loadPDFsAndMarkLoaded()
        } else {
            refreshList()
        }
    }
    
    func refreshList() {
        // Re-apply selection to update sort order (e.g. for "Recent") or filter
        applySelection()
    }

    func loadPDFs() -> AnyPublisher<[PDFModelData], Error> {
        isLoading = true

        return repository.retrieve()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] models in
                self?.allPdfModels = models.sorted(by: { $0.lastOpenTime ?? .distantPast > $1.lastOpenTime ?? .distantPast })
                self?.applySelection()
                self?.isLoaded = true
            }, receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            })
            .eraseToAnyPublisher()
    }

    func loadPDFsAndMarkLoaded() {
        loadPDFs()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    func toggleFavorite(for model: PDFModelData) {
        model.toggleFavorite()
        repository.update(updatedPdfData: model)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] updatedModel in
                self?.UpdatePdfList(updatedModel: updatedModel)
            })
            .store(in: &cancellables)
    }

    private func UpdatePdfList(updatedModel: PDFModelData) {
        if let index = allPdfModels.firstIndex(where: { $0.key == updatedModel.key }) {
            allPdfModels[index] = updatedModel
            applySelection()
        }
    }
    
    func importPDFsAndForget(urls: [BookmarkDataClass]) {
        let existingKeys = Set(allPdfModels.map { $0.key })
        let vm = PDFImportViewModel(bookmarkDatas: urls, repository: repository, existingKeys: existingKeys)
        
        vm.onCompletion = { [weak self] newModels in
            guard let self = self else { return }
            
            // Locally update the list
            self.allPdfModels.append(contentsOf: newModels)
            
            // Update folder if needed
            if case .folder(let currentFolder) = self.currentSelection {
                let newKeys = newModels.map { $0.key }
                var updatedPdfIds = currentFolder.pdfIds
                for key in newKeys {
                    if !updatedPdfIds.contains(key) {
                        updatedPdfIds.append(key)
                    }
                }
                currentFolder.pdfIds = updatedPdfIds
                self.updateFolder(currentFolder)
            }
            
            self.applySelection()
        }
        
        self.importViewModel = vm
        self.isShowingImportProgress = true
    }

    func deletePdf(indexSet: IndexSet) {
        let pdfsToDelete = indexSet.map { visiblePdfModels[$0] }
        deletePdfs(pdfsToDelete)
    }

    func deletePdfs(_ pdfs: [PDFModelData]) {
        for pdf in pdfs {
            repository.delete(pdfKey: pdf.key)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] isSuccess in
                    if isSuccess {
                        self?.visiblePdfModels.removeAll { $0.key == pdf.key }
                        self?.allPdfModels.removeAll { $0.key == pdf.key }
                    }
                })
                .store(in: &cancellables)
        }
    }
    
    deinit{
        cancellables.removeAll()
    }
}

extension PDFListViewModel {
    
    func updateSelection(_ selection: PDFListSelection) {
        currentSelection = selection
        applySelection()
    }

    private func applySelection() {
        let filteredModels: [PDFModelData]
        switch currentSelection {
        case .all:
            filteredModels = allPdfModels
        case .favorite:
            filteredModels = allPdfModels.filter { $0.isFavorite }
        case .recent:
            filteredModels = allPdfModels.sorted(by: { $0.lastOpenTime ?? .distantPast > $1.lastOpenTime ?? .distantPast })
        case .folder(let folder):
            filteredModels = allPdfModels.filter { folder.pdfIds.contains($0.key) }
        }

        if searchText.isEmpty {
            visiblePdfModels = filteredModels
        } else {
            let query = searchText.lowercased()
            visiblePdfModels = filteredModels.filter { pdf in
                (pdf.title?.lowercased().contains(query) ?? false) ||
                (pdf.author?.lowercased().contains(query) ?? false)
            }
        }
    }
    
    func getRecentFiles() -> [PDFModelData] {
        allPdfModels.sorted(by: { $0.lastOpenTime ?? .distantPast > $1.lastOpenTime ?? .distantPast })
    }

    var lastOpenedPdf: PDFModelData? {
        visiblePdfModels
            .filter { $0.lastOpenTime != nil }
            .sorted { $0.lastOpenTime! > $1.lastOpenTime! }
            .first
    }

    // MARK: - Multi-Select Actions

    func enterMultiSelectMode(with pdfKey: String? = nil) {
        isMultiSelectMode = true
        selectedPDFKeys.removeAll()
        if let key = pdfKey {
            selectedPDFKeys.insert(key)
        }
    }

    func exitMultiSelectMode() {
        isMultiSelectMode = false
        selectedPDFKeys.removeAll()
    }

    func toggleSelection(for pdfKey: String) {
        if selectedPDFKeys.contains(pdfKey) {
            selectedPDFKeys.remove(pdfKey)
        } else {
            selectedPDFKeys.insert(pdfKey)
        }
    }

    func selectAll() {
        let allVisibleKeys = visiblePdfModels.map { $0.key }
        selectedPDFKeys = Set(allVisibleKeys)
    }

    func deselectAll() {
        selectedPDFKeys.removeAll()
    }

    func deleteSelectedPDFs() {
        let pdfsToDelete = visiblePdfModels.filter { selectedPDFKeys.contains($0.key) }
        deletePdfs(pdfsToDelete)
        exitMultiSelectMode()
    }

    func moveSelectedPDFs(to folder: FolderModelData?) {
        let pdfsToMove = visiblePdfModels.filter { selectedPDFKeys.contains($0.key) }
        movePDFs(pdfsToMove, to: folder)
        exitMultiSelectMode()
    }
}

extension PDFModelData {
    func toggleFavorite() {
        return isFavorite.toggle()
    }
}


