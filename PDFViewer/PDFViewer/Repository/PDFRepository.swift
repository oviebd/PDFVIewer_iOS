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
    func insert(pdfDatas: [PDFCoreDataModel]) -> AnyPublisher<[PDFFile], Error>
    func retrieve() -> AnyPublisher<[PDFFile], Error>
    func toggleFavorite(pdfItem: PDFCoreDataModel) -> AnyPublisher<PDFFile, Error>
    func delete(pdfItem: PDFCoreDataModel) -> AnyPublisher<Bool, Error>
}

final class PDFLocalRepositoryImpl: PDFRepositoryProtocol {
    private let store: PDFLocalDataStore

    init(store: PDFLocalDataStore) {
        self.store = store
    }

    func insert(pdfDatas: [PDFCoreDataModel]) -> AnyPublisher<[PDFFile], Error> {
        store.insert(pdfDatas: pdfDatas)
            .tryMap { coreDataList in
                coreDataList.compactMap { model in
                    do {
                        var isStale = false
                        let url = try URL(resolvingBookmarkData: model.data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
                        return Self.mapURLtoPDFFile(url: url, key: model.key)
                    } catch {
                        return nil
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    func retrieve() -> AnyPublisher<[PDFFile], Error> {
        store.retrieve()
            .tryMap { coreDataList in
                coreDataList.compactMap { model in
                    do {
                        var isStale = false
                        let url = try URL(resolvingBookmarkData: model.data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
                        return Self.mapURLtoPDFFile(url: url, key: model.key)
                    } catch {
                        return nil
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    func toggleFavorite(pdfItem: PDFCoreDataModel) -> AnyPublisher<PDFFile, Error> {
        let updated = pdfItem.togglingFavorite()
        return store.update(updatedData: updated)
            .tryMap { _ in
                var isStale = false
                let url = try URL(resolvingBookmarkData: updated.data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
                return Self.mapURLtoPDFFile(url: url, key: updated.key)
                //  let url = try URL(resolvingBookmarkData: updated.data, options: [], relativeTo: nil, bookmarkDataIsStale:false)
            } // { _ in updated }
            .eraseToAnyPublisher()
    }

    func delete(pdfItem: PDFCoreDataModel) -> AnyPublisher<Bool, Error> {
        store.delete(updatedData: pdfItem)
    }

    private static func mapURLtoPDFFile(url: URL, key: String) -> PDFFile {
        guard let document = PDFDocument(url: url) else {
            return PDFFile(name: url.lastPathComponent, url: url, metadata: PDFMetadata(image: nil, author: "Unknown", title: url.lastPathComponent), pdfKey: key)
        }

        let page = document.page(at: 0)
        let image = page?.thumbnail(of: CGSize(width: 100, height: 140), for: .cropBox)
        let author = document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown"
        let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url.lastPathComponent

        return PDFFile(name: url.lastPathComponent, url: url, metadata: PDFMetadata(image: image, author: author, title: title), pdfKey: key)
    }
}
