//
//  PDFLocalDataStoreTests.swift
//  PDFViewerTests
//
//  Created by Habibur Rahman on 14/4/25.
//

import XCTest
@testable import PDFViewer
import PDFKit

final class PDFLocalDataStoreTests: XCTestCase {

    //Tests
    
    func test_insertStatus_NewDataWillInsertSuccessfully() throws {
        let sut = try makeSUT()
        let firstPdfData = createDummyPDFCoreDataModel(key: "first")
        let secondPdfData = createDummyPDFCoreDataModel(key: "second")
        
        let exp = expectation(description: "waitig for insertion")
        sut.insertPDFDatas(pdfDatas: [firstPdfData,secondPdfData]) { isSuccess in
            XCTAssertTrue(isSuccess)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
//        insert(sut, statusList: [singleStatus])
//        expect(sut, toRetrieve: [singleStatus])
    }
    
    
    // Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> PDFLocalDataLoader {
        let store = try PDFLocalDataStore(storeURL: inMemoryStoreURL())
        let sut = PDFLocalDataLoader(store: store)

        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func inMemoryStoreURL() -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }

}


func createDummyPDFCoreDataModel(pdfTitle: String = "Test PDF", pdfAuthor: String = "John Doe", pdfPageCount: Int = 3, key : String, isfavorite : Bool = false, lastOpenedDate : Date? = nil) -> PDFCoreDataModel {
    
    let pdfData : Data = createDummyPDF(title: pdfTitle, author: pdfAuthor, pageCount: pdfPageCount).dataRepresentation()!
    return PDFCoreDataModel(key: key, data: pdfData, isFavourite: isfavorite)
}

func createDummyPDF(title: String = "Test PDF", author: String = "John Doe", pageCount: Int = 3) -> PDFDocument {
    let pdfDocument = PDFDocument()
    
    for i in 0..<pageCount {
        let page = PDFPage()
        pdfDocument.insert(page, at: i)
    }

    // Set metadata
    pdfDocument.documentAttributes = [
        PDFDocumentAttribute.titleAttribute: title,
        PDFDocumentAttribute.authorAttribute: author
    ]

    // Bookmark data is usually created from PDFDocument's data
    return pdfDocument//.dataRepresentation()
}

//func getPdfData(pdfDocument : PDFDocument?) -> Data? {
//    return pdfDocument?.dataRepresentation()
//}
