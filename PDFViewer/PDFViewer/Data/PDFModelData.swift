//
//  PDFModelData.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/5/25.
//

import Foundation
import PDFKit

class PDFModelData: Identifiable {
    let id: String = UUID().uuidString
    let key: String
    var urlPath: String?
    var title: String?
    var author: String?
    let bookmarkData: Data?
    var isFavorite: Bool
    var lastOpenedPage: Int
    var lastOpenTime: Date?

    var thumbImage: UIImage?
    var totalPageCount: Int = 0

    init(key: String,
         bookmarkData: Data?,
         isFavorite: Bool,
         lastOpenedPage: Int,
         lastOpenTime: Date?) {
        self.key = key

        self.bookmarkData = bookmarkData
        self.isFavorite = isFavorite
        self.lastOpenedPage = lastOpenedPage
        self.lastOpenTime = lastOpenTime

        decomposeBookmarkData()
    }
}

extension PDFModelData: Equatable, Hashable {
    // MARK: - Equatable

    static func == (lhs: PDFModelData, rhs: PDFModelData) -> Bool {
        return lhs.key == rhs.key
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

extension PDFModelData {
    private func decomposeBookmarkData() {
        var isStale = false
        guard let bookmarkData = bookmarkData,
              let url = try? URL(resolvingBookmarkData: bookmarkData, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale) else { return }

        urlPath = url.absoluteString
        guard let document = PDFDocument(url: url) else {
            return
        }

        let page = document.page(at: 0)
        thumbImage = page?.thumbnail(of: CGSize(width: 100, height: 140), for: .cropBox)
        totalPageCount = document.pageCount
        author = document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown"
        title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url.lastPathComponent
    }
}

extension PDFModelData {
    func toCoereDataModel() -> PDFCoreDataModel {
        return PDFCoreDataModel(key: key,
                                bookmarkData: bookmarkData,
                                isFavourite: isFavorite,
                                lastOpenPage: lastOpenedPage,
                                lastOpenTime: lastOpenTime)
    }
}

let sampleUrl: URL = Bundle.main.url(forResource: "sample1", withExtension: "pdf")!

let samplePDFModelData = PDFModelData(key: "sample_pdf_001", bookmarkData: sampleUrl.toBookmarData(), isFavorite: false, lastOpenedPage: 0, lastOpenTime: nil)

// let samplePDFFile = PDFModelData(
//    name: "Sample Document",
//    url: URL(fileURLWithPath: "/path/to/sample.pdf"), data: nil,
//    metadata: PDFMetadata(
//        image: nil, author: "Sample author", title: "Sample title"
//    ),
//    pdfKey: "sample_pdf_001", isFavorite: false
// )

// static func maptoPDFFile(url: URL, coreDataModel : PDFCoreDataModel) -> PDFFile {
//    guard let document = PDFDocument(url: url) else {
//        return PDFFile(name: url.lastPathComponent, url: url, data: coreDataModel.data, metadata: PDFMetadata(image: nil, author: "Unknown", title: url.lastPathComponent), pdfKey: coreDataModel.key, isFavorite: false)
//    }
//
//    let page = document.page(at: 0)
//    let image = page?.thumbnail(of: CGSize(width: 100, height: 140), for: .cropBox)
//    let author = document.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown"
//    let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url.lastPathComponent
//
//    return PDFFile(name: url.lastPathComponent, url: url, data: coreDataModel.data, metadata: PDFMetadata(image: image, author: author, title: title), pdfKey: coreDataModel.key, isFavorite: coreDataModel.isFavourite)
// }

//
// let samplePDFFile = PDFFile(
//    name: "Sample Document",
//    url: URL(fileURLWithPath: "/path/to/sample.pdf"), data: nil,
//    metadata: PDFMetadata(
//        image: nil, author: "Sample author", title: "Sample title"
//    ),
//    pdfKey: "sample_pdf_001", isFavorite: false
// )
