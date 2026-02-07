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

    private var repository: PDFRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    @Published var isLoading = false
    @Published var errorMessage: String?

    init(repository: PDFRepositoryProtocol) {
        self.repository = repository
        loadFolders()
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

    func loadPDFs() -> AnyPublisher<[PDFModelData], Error> {
        isLoading = true

        return repository.retrieve()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] models in
                self?.allPdfModels = models
                self?.applySelection()
            }, receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            })
            .eraseToAnyPublisher()
    }

    func loadPDFsAndForget() {
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
        }
    }
    
    func importPDFs(bookmarkDatas: [BookmarkDataClass]) -> AnyPublisher<Void, Error> {
        let pdfCoreDataList = bookmarkDatas.compactMap { url -> PDFModelData? in
            return PDFModelData(key: url.key, bookmarkData: url.data, annotationdata: nil, isFavorite: false, lastOpenedPage: 0, lastOpenTime: nil)
        }

        return repository.insert(pdfDatas: pdfCoreDataList)
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] _ -> AnyPublisher<[PDFModelData], Error> in
                guard let self = self else {
                    return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
                }
                
                if case .folder(let currentFolder) = self.currentSelection {
                    let newKeys = pdfCoreDataList.map { $0.key }
                    var updatedPdfIds = currentFolder.pdfIds
                    for key in newKeys {
                        if !updatedPdfIds.contains(key) {
                            updatedPdfIds.append(key)
                        }
                    }
                    currentFolder.pdfIds = updatedPdfIds
                    self.updateFolder(currentFolder)
                }
                
                return self.loadPDFs()
            }
            .map { _ in () } // return Void instead of model list
            .eraseToAnyPublisher()
    }

//    func importPDFs(urls: [URL]) -> AnyPublisher<Void, Error> {
//        let pdfCoreDataList = urls.compactMap { url -> PDFModelData? in
//            do {
//               // let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
//                let bookmark = try url.bookmarkData(
//                    options: .withSecurityScope,
//                    includingResourceValuesForKeys: nil,
//                    relativeTo: nil
//                )
//                let key = Self.generatePDFKey(for: url)
//
//                return PDFModelData(key: key, bookmarkData: bookmark, isFavorite: false, lastOpenedPage: 0, lastOpenTime: nil)
//            } catch {
//                return nil
//            }
//        }
//
//        return repository.insert(pdfDatas: pdfCoreDataList)
//            .receive(on: DispatchQueue.main)
//            .flatMap { [weak self] _ -> AnyPublisher<[PDFModelData], Error> in
//                guard let self = self else {
//                    return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
//                }
//                return self.loadPDFs()
//            }
//            .map { _ in () } // return Void instead of model list
//            .eraseToAnyPublisher()
//    }

//    func importPDFsAndForget(urls: [URL]) {
//        importPDFs(urls: urls)
//            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
//            .store(in: &cancellables)
//    }
    
    func importPDFsAndForget(urls: [BookmarkDataClass]) {
        importPDFs(bookmarkDatas: urls)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    func deletePdf(indexSet: IndexSet) {
        if let index = indexSet.first {
            
            let pdfToDelete = visiblePdfModels[index]

            repository.delete(pdfKey: pdfToDelete.key)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] isSuccess in

                    if isSuccess {
                        self?.visiblePdfModels.remove(at: index)
                        self?.allPdfModels.removeAll { $0.key == pdfToDelete.key }
                    }
                })
                .store(in: &cancellables)
        }
    }

    private static func generatePDFKey(for url: URL) -> String {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            let fileSize = resourceValues.fileSize ?? 0
            let creationDate = resourceValues.creationDate?.timeIntervalSince1970 ?? 0
            let combinedString = "\(fileSize)-\(creationDate)"
            let hash = SHA256.hash(data: Data(combinedString.utf8))
            return hash.map { String(format: "%02x", $0) }.joined()
        } catch {
            return UUID().uuidString
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
        switch currentSelection {
        case .all:
            visiblePdfModels = allPdfModels
        case .favorite:
            visiblePdfModels = allPdfModels.filter { $0.isFavorite }
        case .recent:
            visiblePdfModels = allPdfModels.sorted(by: { $0.lastOpenTime ?? .distantPast > $1.lastOpenTime ?? .distantPast })
        case .folder(let folder):
            visiblePdfModels = allPdfModels.filter { folder.pdfIds.contains($0.key) }
        }
    }
    
    func getRecentFiles() -> [PDFModelData] {
        allPdfModels.sorted(by: { $0.lastOpenTime ?? .distantPast > $1.lastOpenTime ?? .distantPast })
    }
}

extension PDFModelData {
    func toggleFavorite() {
        return isFavorite.toggle()
    }
}


