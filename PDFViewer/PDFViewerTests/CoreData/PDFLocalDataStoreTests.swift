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
    
    func test_insert_NewDataWillInsertSuccessfully() throws {
        let sut = try makeSUT()
        let firstPdfData = createDummyPDFCoreDataModel(key: "first")
        let secondPdfData = createDummyPDFCoreDataModel(key: "second")
        
        insert(sut, datas: [firstPdfData,secondPdfData])
        expect(sut, toRetrieve: [firstPdfData,secondPdfData])
    }
    
    func test_insert_ExistingDataWillNotInsert() throws {
        let sut = try makeSUT()
        let firstPdfData = createDummyPDFCoreDataModel(key: "first")
        let secondPdfData = createDummyPDFCoreDataModel(key: "second")
        let thirdPdfData = createDummyPDFCoreDataModel(key: "first")
        
        insert(sut, datas: [firstPdfData,secondPdfData,thirdPdfData])
        expect(sut, toRetrieve: [firstPdfData,secondPdfData])
       
    }
    
    func test_insert_PreviouslyExistingDataWillNotInsert() throws {
        let sut = try makeSUT()
        let firstPdfData = createDummyPDFCoreDataModel(key: "first")
        let secondPdfData = createDummyPDFCoreDataModel(key: "second")
        let thirdPdfData = createDummyPDFCoreDataModel(key: "first")
        
        insert(sut, datas: [firstPdfData,secondPdfData])
        expect(sut, toRetrieve: [firstPdfData,secondPdfData])
        insert(sut, datas: [thirdPdfData])
        expect(sut, toRetrieve: [firstPdfData,secondPdfData])
    }
    
    func test_favorite_UpdateFavoriteData() throws {
        let sut = try makeSUT()
        let firstFavoriteItem = createDummyPDFCoreDataModel(key: "first",isfavorite: true)
        let secondNotFavoritePdfData = createDummyPDFCoreDataModel(key: "second",isfavorite: false)
        
        let expectation = self.expectation(description: "Toggle favorite")
        
        insert(sut, datas: [firstFavoriteItem,secondNotFavoritePdfData])
        sut.toggleFavorite(pdfItem: firstFavoriteItem) { [weak self] updatedData, isSuccess in
            XCTAssertTrue(isSuccess)
            XCTAssertFalse(updatedData!.isFavourite)
            
            sut.retrieve { datas in
                self?.comparePDFData(expectedDatas: [updatedData!,secondNotFavoritePdfData], actualdata: datas!)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 5.0)
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

    @discardableResult
    func insert(_ sut: PDFLocalDataLoader, datas: [PDFCoreDataModel], file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let exp = expectation(description: "waitig for insertion")
        var isInsertionSuccess = false

        sut.insertPDFDatas(pdfDatas: datas) { isSuccess in
            isInsertionSuccess = isSuccess
            XCTAssertTrue(isSuccess)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return isInsertionSuccess
    }
    
    @discardableResult
    func retrieve(_ sut: PDFLocalDataLoader, file: StaticString = #filePath, line: UInt = #line) -> [PDFCoreDataModel]? {
        let exp = expectation(description: "waitig for insertion")
        var localDatas : [PDFCoreDataModel] = []
        sut.retrieve { datas in
            localDatas = datas ?? []
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return localDatas
    }
    

    
    func expect(_ sut: PDFLocalDataLoader, toRetrieve expectedDatas: [PDFCoreDataModel], file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve { fetchedInspection in

            let dataList = fetchedInspection ?? []
            
            self.comparePDFData(expectedDatas: expectedDatas, actualdata: dataList, file: file, line: line)
//            XCTAssertEqual(dataList.count, expectedDatas.count, file: file, line: line)
//
//            for i in 0..<expectedDatas.count {
//                XCTAssertEqual(dataList[i].key, expectedDatas[i].key,file: file, line: line)
//                XCTAssertEqual(dataList[i].isFavourite, expectedDatas[i].isFavourite,file: file, line: line)
//            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 10)
    }
    
    func comparePDFData(expectedDatas: [PDFCoreDataModel], actualdata :  [PDFCoreDataModel] , file: StaticString = #file, line: UInt = #line)  {
      
        let dataList = actualdata
        XCTAssertEqual(dataList.count, expectedDatas.count, file: file, line: line)

        for i in 0..<expectedDatas.count {
            XCTAssertEqual(dataList[i].key, expectedDatas[i].key,file: file, line: line)
            XCTAssertEqual(dataList[i].isFavourite, expectedDatas[i].isFavourite,file: file, line: line)
        }
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
