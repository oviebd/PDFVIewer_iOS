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
    @Published var pdfModels: [PDFModelData] = []

    private var repository: PDFRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    @Published var isLoading = false
    @Published var errorMessage: String?

    init(repository: PDFRepositoryProtocol) {
        self.repository = repository
        // loadPDFs()
    }

//    func loadPDFs() {
//        isLoading = true
//        repository.retrieve()
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { [weak self] completion in
//                self?.isLoading = false
//                if case let .failure(error) = completion {
//                    print("Error: \(error.localizedDescription)")
//                    self?.errorMessage = error.localizedDescription
//                }
//            }, receiveValue: { [weak self] models in
//                self?.pdfModels = models
//            })
//            .store(in: &cancellables)
//    }

    func loadPDFs() -> AnyPublisher<[PDFModelData], Error> {
        isLoading = true
        return repository.retrieve()
            .handleEvents(receiveOutput: { [weak self] models in
                self?.pdfModels = models
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

    func UpdatePdfList(updatedModel : PDFModelData){
        if let index = pdfModels.firstIndex(where: { $0.key == updatedModel.key }) {
            pdfModels[index] = updatedModel
        }
    }

    func importPDFs(urls: [URL]) -> AnyPublisher<Void, Error> {
        let pdfCoreDataList = urls.compactMap { url -> PDFModelData? in
            do {
                let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
                let key = Self.generatePDFKey(for: url)

                return PDFModelData(key: key, bookmarkData: bookmark, isFavorite: false, lastOpenedPage: 0, lastOpenTime: nil)

                // return PDFCoreDataModel(key: key, data: bookmark, isFavourite: false)
            } catch {
                return nil
            }
        }

        return repository.insert(pdfDatas: pdfCoreDataList)
            .map { _ in () }
            .eraseToAnyPublisher()
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
}

extension PDFModelData {
    func toggleFavorite() {
        return isFavorite.toggle()
    }
}
