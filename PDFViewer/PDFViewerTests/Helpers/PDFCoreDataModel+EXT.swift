//
//  PDFCoreDataModel+EXT.swift
//  PDFViewerTests
//
//  Created by Habibur Rahman on 9/5/25.
//

import Foundation
@testable import PDFViewer
import PDFKit

func createDummyPDFCoreDataModel(pdfTitle: String = "Test PDF", pdfAuthor: String = "John Doe", pdfPageCount: Int = 3, key: String, isfavorite: Bool = false, lastOpenedDate: Date? = nil) -> PDFCoreDataModel {
    let pdfData: Data = createDummyPDFDocument(title: pdfTitle, author: pdfAuthor, pageCount: pdfPageCount).dataRepresentation()!
    return PDFCoreDataModel(key: key, bookmarkData: pdfData, isFavourite: isfavorite, lastOpenPage: 0, lastOpenTime: lastOpenedDate, annotationData: nil)

}

func createDummyPDFDocument(title: String = "Test PDF", author: String = "John Doe", pageCount: Int = 3) -> PDFDocument {
    let pdfDocument = PDFDocument()

    for i in 0 ..< pageCount {
        let page = PDFPage()
        pdfDocument.insert(page, at: i)
    }

    // Set metadata
    pdfDocument.documentAttributes = [
        PDFDocumentAttribute.titleAttribute: title,
        PDFDocumentAttribute.authorAttribute: author,
    ]

    return pdfDocument
}



extension PDFCoreDataModel: @retroactive Equatable, @retroactive Hashable {
    public static func == (lhs: PDFCoreDataModel, rhs: PDFCoreDataModel) -> Bool {
        return lhs.key == rhs.key &&
            lhs.isFavourite == rhs.isFavourite
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(isFavourite)
    }
}
