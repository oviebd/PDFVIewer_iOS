//
//  PDFManager.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/4/25.
//

//import CryptoKit
//import Foundation
//import PDFKit
import SwiftUI
//import UniformTypeIdentifiers
//
struct PDFFile: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let metadata: PDFMetadata
    let pdfKey: String
}

struct PDFMetadata {
    let image: UIImage?
    let author: String
    let title: String
}
//
//
//class PDFManager: ObservableObject {
//    @Published var pdfFiles: [PDFFile] = []
//
//    let manager = PdfCoreDataManager()
//
//    func loadSelectedPDFFiles(urls: [URL]) {
//        DispatchQueue.global(qos: .userInitiated).async {
//            let pdfs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
//                .map { PDFFile(name: $0.lastPathComponent, url: $0, metadata: self.extractPDFMetadata(from: $0), pdfKey: self.generatePDFKey(for: $0)) }
//
//            DispatchQueue.main.async {
//                self.pdfFiles = pdfs
//                //self.savePDFBookmarks(urls: urls)
//            }
//        }
//    }
//
//    func extractPDFMetadata(from url: URL) -> PDFMetadata {
//        guard let pdfDocument = PDFDocument(url: url) else {
//            return PDFMetadata(image: nil, author: "Unknown", title: url.lastPathComponent)
//        }
//
//        // 🖼 Extract first page as image
//        let page = pdfDocument.page(at: 0)
//        let image = page?.thumbnail(of: CGSize(width: 100, height: 140), for: .cropBox)
//
//        // 📖 Extract metadata
//        let author = pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown"
//        let title = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url.lastPathComponent
//
//        return PDFMetadata(image: image, author: author, title: title)
//    }
//
////    func restorePDFsFromBookmarks() async {
////        guard let savedBookmarksDict = UserDefaults.standard.dictionary(forKey: "SavedPDFBookmarks") as? [String: Data] else {
////            return
////        }
////
////        var restoredPDFs: [PDFFile] = []
////
////        for (key, bookmarkData) in savedBookmarksDict {
////            var isStale = false
////            do {
////                let url = try URL(resolvingBookmarkData: bookmarkData, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
////                let metadata = extractPDFMetadata(from: url)
////                let pdfFile = PDFFile(name: url.lastPathComponent, url: url, metadata: metadata, pdfKey: key)
////                restoredPDFs.append(pdfFile)
////
////                print("U>> restored key is -  \(key) - name - \(pdfFile.name) - title \(pdfFile.metadata.title)")
//////                if isStale {
//////                    print("⚠️ Bookmark for key \(key) is stale.")
//////                }
////            } catch {
////                print("❌ Error restoring bookmark for key \(key): \(error)")
////            }
////        }
////
////        // ✅ Fix: assign to a `let` copy before calling `await`
////        let finalPDFs = restoredPDFs
////
////        await MainActor.run {
////            self.pdfFiles = finalPDFs
////        }
////    }
////
////    func savePDFBookmarksInDB(urls: [URL]) {
////        // Step 1: Load existing dictionary of bookmarks
////        var coreDataList: [PDFCoreDataModel] = getPDFCoreDataList(urls: urls)
////
////        dataLoader?.insertPDFDatas(pdfDatas: coreDataList)
////            .sink(receiveCompletion: { completion in
////                switch completion {
////                case .finished:
////                    print("Insert completed")
////                case let .failure(error):
////                    break
////                }
////            }, receiveValue: { insertedPDFs in
////                print("Inserted: \(insertedPDFs.count) new items")
////
////            })
////            .store(in: &cancellables)
////    }
//
//    func getPDFCoreDataList(urls: [URL]) -> [PDFCoreDataModel] {
//        var coreDataList = [PDFCoreDataModel]()
//
//        for url in urls {
//            do {
//                let bookmark = try url.bookmarkData(
//                    options: [],
//                    includingResourceValuesForKeys: nil,
//                    relativeTo: nil
//                )
//
//                let key = generatePDFKey(for: url)
//                coreDataList.append(PDFCoreDataModel(key: key, data: bookmark, isFavourite: false))
//            } catch {
//                print("❌ Error creating bookmark for \(url): \(error)")
//            }
//        }
//
//        return coreDataList
//    }
//
//    func generatePDFKey(for url: URL) -> String {
//        do {
//            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
//
//            let fileSize = resourceValues.fileSize ?? 0
//            let creationDate = resourceValues.creationDate?.timeIntervalSince1970 ?? 0
//
//            let combinedString = "\(fileSize)-\(creationDate)"
//            let hash = SHA256.hash(data: Data(combinedString.utf8))
//            return hash.map { String(format: "%02x", $0) }.joined()
//
//        } catch {
//            print("❌ Error getting metadata for \(url): \(error)")
//            return UUID().uuidString // fallback
//        }
//    }
//}
