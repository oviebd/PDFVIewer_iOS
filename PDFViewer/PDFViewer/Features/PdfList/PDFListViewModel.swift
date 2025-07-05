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
    @Published var loadingMessage: String = ""
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
        let totalToImport = bookmarkDatas.count
        var importedCount = 0

        let pdfsToInsert = bookmarkDatas.map {
            PDFModelData(key: $0.key, bookmarkData: $0.data, isFavorite: false, lastOpenedPage: 0, lastOpenTime: nil)
        }

        let initialPublisher = Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()

        let combinedPublisher = pdfsToInsert.reduce(initialPublisher) { (previousPublisher, pdfData) in
            return previousPublisher.flatMap { _ -> AnyPublisher<Void, Error> in
                self.repository.insert(pdfDatas: [pdfData])
                    .receive(on: DispatchQueue.main)
                    .handleEvents(receiveOutput: { _ in
                        importedCount += 1
                        self.loadingMessage = "Importing \(pdfData.title ?? "") (\(importedCount)/\(totalToImport))"
                    })
                    .map { _ in () }
                    .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
        }

        return combinedPublisher.flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
            guard let self = self else {
                return Fail(error: URLError(.badServerResponse)).eraseToAnyPublisher()
            }
            return self.loadPDFs().map { _ in () }.eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    func importPDFsAndForget(bookmarkDatas: [BookmarkDataClass]) {
        // isLoading is already true from the onStart closure in the View
        self.loadingMessage = "Importing 0/\(bookmarkDatas.count)"

        importPDFs(bookmarkDatas: bookmarkDatas)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                self?.loadingMessage = ""
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { _ in })
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


