//
//  PDFLocalDataLoader.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 14/4/25.
//

import Combine
import Foundation

//class PDFLocalDataLoader {
//    public typealias CreationCompletion = (Bool) -> Void
//    private let store: PDFLocalDataStore
//    private var cancellables = Set<AnyCancellable>()
//
//    public init(store: PDFLocalDataStore) {
//        self.store = store
//    }
//
//    public func insertPDFDatas(
//        pdfDatas: [PDFCoreDataModel]) -> AnyPublisher<[PDFCoreDataModel], Error> {
//        store.insert(pdfDatas: pdfDatas)
//            .eraseToAnyPublisher()
//    }
//
//    public func retrieve() -> AnyPublisher<[PDFCoreDataModel], Error> {
//        store.retrieve()
//            .eraseToAnyPublisher()
//    }
//
//    public func toggleFavorite(pdfItem: PDFCoreDataModel) -> AnyPublisher<PDFCoreDataModel, Error> {
//        let newItem = PDFCoreDataModel(key: pdfItem.key, data: pdfItem.data, isFavourite: !pdfItem.isFavourite)
//
//        return store.update(updatedData: newItem)
//            .tryMap { isSuccess in
//                guard isSuccess else {
//                    throw NSError(domain: "ToggleFavorite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
//                }
//                return newItem
//            }
//            .eraseToAnyPublisher()
//    }
//    
//    public func deletePdfData(pdfItem: PDFCoreDataModel) -> AnyPublisher<Bool, Error> {
//
//        return store.delete(updatedData: pdfItem)
//            .tryMap { isSuccess in
//                guard isSuccess else {
//                    throw NSError(domain: "deletePdfData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
//                }
//                return isSuccess
//            }
//            .eraseToAnyPublisher()
//    }
//}
