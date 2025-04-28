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
    @Published var pdfModels: [PDFFile] = []

    private var repository: PDFRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(repository: PDFRepositoryProtocol) {
        self.repository = repository
        loadPDFs()
    }

    func loadPDFs() {
        isLoading = true
        repository.retrieve()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    print("Error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] models in
                self?.pdfModels = models
            })
            .store(in: &cancellables)
    }

//    func toggleFavorite(for model: PDFCoreDataModel) {
//        repository.toggleFavorite(pdfItem: model)
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] updatedModel in
//                if let index = self?.pdfModels.firstIndex(where: { $0.key == updatedModel.key }) {
//                    self?.pdfModels[index] = updatedModel
//                }
//            })
//            .store(in: &cancellables)
//    }

    func importPDFs(urls: [URL]) -> AnyPublisher<Void, Error> {
        let pdfCoreDataList = urls.compactMap { url -> PDFCoreDataModel? in
            do {
                let bookmark = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
                let key = Self.generatePDFKey(for: url)
                return PDFCoreDataModel(key: key, data: bookmark, isFavourite: false)
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

//    @Published private(set) var pdfFiles: [PDFFile] = []
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//
//    private let repository: PDFRepository
//    private var cancellables = Set<AnyCancellable>()
//
//    init(repository: PDFRepository) {
//        self.repository = repository
//    }
//
//    func loadPDFs() {
//        isLoading = true
//        repository.fetchPDFs()
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { [weak self] completion in
//                self?.isLoading = false
//                if case .failure(let error) = completion {
//                    self?.errorMessage = error.localizedDescription
//                }
//            }, receiveValue: { [weak self] files in
//                self?.pdfFiles = files
//            })
//            .store(in: &cancellables)
//    }
//
//    func importPDFs(urls: [URL]) {
//        isLoading = true
//        repository.importPDFs(urls: urls)
//            .flatMap { [weak self] _ in
//                self?.repository.fetchPDFs() ?? Empty().eraseToAnyPublisher()
//            }
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { [weak self] completion in
//                self?.isLoading = false
//                if case .failure(let error) = completion {
//                    self?.errorMessage = error.localizedDescription
//                }
//            }, receiveValue: { [weak self] files in
//                self?.pdfFiles = files
//            })
//            .store(in: &cancellables)
//    }
}
