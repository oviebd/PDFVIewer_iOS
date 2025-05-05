//
//  PDFRepository.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 27/4/25.
//

import Combine
import CryptoKit
import Foundation
import PDFKit

protocol PDFRepositoryProtocol {
    func insert(pdfDatas: [PDFModelData]) -> AnyPublisher<Bool, Error>
    func retrieve() -> AnyPublisher<[PDFModelData], Error>
    // func toggleFavorite(pdfItem: PDFModelData) -> AnyPublisher<PDFModelData, Error>
    // func delete(pdfKey: String) -> AnyPublisher<Bool, Error>
}

final class PDFLocalRepositoryImpl: PDFRepositoryProtocol {
    private let store: PDFLocalDataStore

    init(store: PDFLocalDataStore) {
        self.store = store
    }

    func insert(pdfDatas: [PDFModelData]) -> AnyPublisher<Bool, Error> {
        var coreDataModels = [PDFCoreDataModel]()
        for pdfData in pdfDatas {
            let coreDataModel = pdfData.toCoereDataModel()
            coreDataModels.append(coreDataModel)
        }

        return store.insert(pdfDatas: coreDataModels)
    }

    func retrieve() -> AnyPublisher<[PDFModelData], Error> {
        store.retrieve()
            .tryMap { pdfCoreDataList in
                pdfCoreDataList.compactMap { singlePDfCoreData in
                    singlePDfCoreData.toPDfModelData()
                }
            }
            .eraseToAnyPublisher()
    }

//    func toggleFavorite(pdfItem: PDFCoreDataModel) -> AnyPublisher<PDFFile, Error> {
//        let updated = pdfItem.togglingFavorite()
//        return store.update(updatedData: updated)
//            .tryMap { _ in
//                var isStale = false
//                let url = try URL(resolvingBookmarkData: updated.data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
//                return Self.maptoPDFFile(url: url, coreDataModel: updated)
//                //  let url = try URL(resolvingBookmarkData: updated.data, options: [], relativeTo: nil, bookmarkDataIsStale:false)
//            } // { _ in updated }
//            .eraseToAnyPublisher()
//    }
//
//    func delete(pdfItem: PDFCoreDataModel) -> AnyPublisher<Bool, Error> {
//        store.delete(updatedData: pdfItem)
//    }
}
