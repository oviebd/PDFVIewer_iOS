//
//  PDFListViewModel.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 27/4/25.
//

import Combine
import CryptoKit
import Foundation

final class PDFListViewModel: ObservableObject {
    
    @Published var selectedSortOption: PDFSortOption = .all
    @Published var allPdfModels: [PDFModelData] = []
    @Published var visiblePdfModels: [PDFModelData] = []

    private var repository: PDFRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    @Published var isLoading = false
    @Published var errorMessage: String?

    init(repository: PDFRepositoryProtocol) {
        self.repository = repository
    }

    func loadPDFs() -> AnyPublisher<[PDFModelData], Error> {
        isLoading = true

        return repository.retrieve()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] models in
                self?.allPdfModels = models
                self?.updateSortOption(.all)
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
            return PDFModelData(key: url.key, bookmarkData: url.data, isFavorite: false, lastOpenedPage: 0, lastOpenTime: nil)
//            do {
//               // let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
////                let bookmark = try url.bookmarkData(
////                    options: .withSecurityScope,
////                    includingResourceValuesForKeys: nil,
////                    relativeTo: nil
////                )
//                //let key = Self.generatePDFKey(for: url)
//
//                return PDFModelData(key: url.key, bookmarkData: url.data, isFavorite: false, lastOpenedPage: 0, lastOpenTime: nil)
//            } catch {
//                return nil
//            }
        }

        return repository.insert(pdfDatas: pdfCoreDataList)
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] _ -> AnyPublisher<[PDFModelData], Error> in
                guard let self = self else {
                    return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
                }
                return self.loadPDFs()
            }
            .map { _ in () } // return Void instead of model list
            .eraseToAnyPublisher()
    }

    
    func importPDFsAndForget(bookmarkDatas: [BookmarkDataClass]) {
        importPDFs(bookmarkDatas: bookmarkDatas)
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
    
    deinit{
        cancellables.removeAll()
    }
}

extension PDFListViewModel {
    
    func updateSortOption(_ option: PDFSortOption) {
        selectedSortOption = option
        applySorting(option)
    }

    private func applySorting(_ option: PDFSortOption) {
        switch option {
        case .all:
            // Load all PDFs
           visiblePdfModels  = allPdfModels
        case .favorite:
            visiblePdfModels = allPdfModels.filter { $0.isFavorite }
        case .recent:
            visiblePdfModels = getRecentFiles()
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


