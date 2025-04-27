//
//  PDFDataVM.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/4/25.
//

import Combine
import Foundation
import PDFKit
import CryptoKit

class PDFDataVM: ObservableObject {
   
    @Published var pdfDataList: [PDFFile] = []

    let dataLoader: PDFLocalDataLoader?
    private var cancellables = Set<AnyCancellable>()

    init() {
        do {
            let store = try PDFLocalDataStore()
            dataLoader = PDFLocalDataLoader(store: store)
        } catch {
            dataLoader = nil
        }
        
        fetchDataFromLocal()
    }
    
    
    func importAndSavePDF(urls: [URL]) {
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
//                .map { PDFFile(name: $0.lastPathComponent, url: $0, metadata: self.extractPDFMetadata(from: $0), pdfKey: self.generatePDFKey(for: $0)) }
             //   .map { PDFCoreDataModel(key: self.generatePDFKey(for: $0), data: self.extractPDFMetadata(from: $0), isFavourite: false) }

            DispatchQueue.main.async {
                self.saveToLocal(pdfCoreDataList: self.getPDFCoreDataList(urls: pdfs))
            }
        }
    }

    func fetchDataFromLocal() {
        dataLoader?.retrieve()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in

                switch completion {
                case .finished:
                    print("Insert completed")
                case let .failure(error):
                    // print("Insert failed with error: \(error)")
                    break
                }
            }, receiveValue: { [weak self] corePDFDataList in
                guard let self else { return }
                self.pdfDataList = []
                for coreData in corePDFDataList {
                    var isStale = false
                    do {
                        let url = try URL(resolvingBookmarkData: coreData.data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
                        let metadata = self.extractPDFMetadata(from: url)
                        let pdfFile = PDFFile(name: url.lastPathComponent, url: url, metadata: metadata, pdfKey: coreData.key)
                        self.pdfDataList.append(pdfFile)

                        print("U>> restored key is -  \(coreData.key) - name - \(pdfFile.name) - title \(pdfFile.metadata.title)")
                    } catch {
                        print("❌ Error restoring bookmark for key \(coreData.key): \(error)")
                    }
                }

            })
            .store(in: &cancellables)
    }

    func saveToLocal(pdfCoreDataList: [PDFCoreDataModel]) {
        dataLoader?.insertPDFDatas(pdfDatas: pdfCoreDataList)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Insert completed")
                case let .failure(error):
                    break
                }
            }, receiveValue: { insertedPDFs in
                print("Inserted: \(insertedPDFs.count) new items")
                self.fetchDataFromLocal()

            })
            .store(in: &cancellables)
    }

    func extractPDFMetadata(from url: URL) -> PDFMetadata {
        guard let pdfDocument = PDFDocument(url: url) else {
            return PDFMetadata(image: nil, author: "Unknown", title: url.lastPathComponent)
        }

        // 🖼 Extract first page as image
        let page = pdfDocument.page(at: 0)
        let image = page?.thumbnail(of: CGSize(width: 100, height: 140), for: .cropBox)

        // 📖 Extract metadata
        let author = pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown"
        let title = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url.lastPathComponent

        return PDFMetadata(image: image, author: author, title: title)
    }
    
    func generatePDFKey(for url: URL) -> String {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])

            let fileSize = resourceValues.fileSize ?? 0
            let creationDate = resourceValues.creationDate?.timeIntervalSince1970 ?? 0

            let combinedString = "\(fileSize)-\(creationDate)"
            let hash = SHA256.hash(data: Data(combinedString.utf8))
            return hash.map { String(format: "%02x", $0) }.joined()

        } catch {
            print("❌ Error getting metadata for \(url): \(error)")
            return UUID().uuidString // fallback
        }
    }
    
    func getPDFCoreDataList(urls: [URL]) -> [PDFCoreDataModel] {
        var coreDataList = [PDFCoreDataModel]()

        for url in urls {
            do {
                let bookmark = try url.bookmarkData(
                    options: [],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )

                let key = generatePDFKey(for: url)
                coreDataList.append(PDFCoreDataModel(key: key, data: bookmark, isFavourite: false))
            } catch {
                print("❌ Error creating bookmark for \(url): \(error)")
            }
        }

        return coreDataList
    }
}
