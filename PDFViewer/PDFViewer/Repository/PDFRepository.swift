//
//  PDFRepository.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 27/4/25.
//

import Foundation
import Combine
import PDFKit
import CryptoKit

protocol PDFRepository {
    func importPDFs(urls: [URL]) -> AnyPublisher<Void, Error>
    func fetchPDFs() -> AnyPublisher<[PDFFile], Error>
}

final class PDFRepositoryImpl: PDFRepository {
 
    private let loader: PDFLocalDataLoader
    
    init(loader: PDFLocalDataLoader) {
        self.loader = loader
    }
    
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
        
        return loader.insertPDFDatas(pdfDatas: pdfCoreDataList)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    func fetchPDFs() -> AnyPublisher<[PDFFile], Error> {
        loader.retrieve()
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
    
    private static func mapURLtoPDFFile(url: URL, key: String) -> PDFFile {
        guard let document = PDFDocument(url: url) else {
            
            return PDFFile(name: url.lastPathComponent, url: url, metadata: PDFMetadata(image: nil, author: "Unknown", title: url.lastPathComponent), pdfKey: key)
            
          //  return PDFFile(id: key, name: url.lastPathComponent, metadata: PDFMetadata(image: nil, author: "Unknown", title: url.lastPathComponent))
        }
        
        let page = document.page(at: 0)
        let image = page?.thumbnail(of: CGSize(width: 100, height: 140), for: .cropBox)
        let author = document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown"
        let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url.lastPathComponent
        
        return PDFFile(name: url.lastPathComponent, url: url, metadata: PDFMetadata(image: image, author: author, title: title), pdfKey: key)
        
        //return PDFFile(id: key, name: url.lastPathComponent, metadata: PDFMetadata(image: image, author: author, title: title))
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
