//
//  PDFLocalDataStoreTests.swift
//  PDFViewerTests
//
//  Created by Habibur Rahman on 14/4/25.
//

import Combine
import PDFKit
@testable import PDFViewer
import XCTest

final class PDFLocalDataStoreTests: XCTestCase {
    // Tests

    private var cancellables = Set<AnyCancellable>()

    func test_insert_NewDataWillInsertSuccessfully() throws {
        let sut = try makeSUT()
        let firstPdfData = createDummyPDFCoreDataModel(key: "first")
        let secondPdfData = createDummyPDFCoreDataModel(key: "second")

        insert(sut, datas: [firstPdfData, secondPdfData])
        expect(sut, toRetrieve: [firstPdfData, secondPdfData])
    }

    func test_insert_ExistingDataWillNotInsert() throws {
        let sut = try makeSUT()
        let firstPdfData = createDummyPDFCoreDataModel(key: "first")
        let secondPdfData = createDummyPDFCoreDataModel(key: "second")
        let thirdPdfData = createDummyPDFCoreDataModel(key: "first")

        insert(sut, datas: [firstPdfData, secondPdfData, thirdPdfData])
        expect(sut, toRetrieve: [firstPdfData, secondPdfData])
    }

    func test_insert_PreviouslyExistingDataWillNotInsert() throws {
        let sut = try makeSUT()
        let firstPdfData = createDummyPDFCoreDataModel(key: "first")
        let secondPdfData = createDummyPDFCoreDataModel(key: "second")
        let thirdPdfData = createDummyPDFCoreDataModel(key: "first")

        insert(sut, datas: [firstPdfData, secondPdfData])
        expect(sut, toRetrieve: [firstPdfData, secondPdfData])
        insert(sut, datas: [thirdPdfData])
        expect(sut, toRetrieve: [firstPdfData, secondPdfData])
    }

    func test_favorite_UpdateFavoriteData() throws {
        let sut = try makeSUT()
        let firstFavoriteItem = createDummyPDFCoreDataModel(key: "first", isfavorite: true)
        let secondNotFavoritePdfData = createDummyPDFCoreDataModel(key: "second", isfavorite: false)

        let expectation = self.expectation(description: "Toggle favorite")

        insert(sut, datas: [firstFavoriteItem, secondNotFavoritePdfData])
        
        sut.toggleFavorite(pdfItem: firstFavoriteItem)
            .flatMap { updatedItem -> AnyPublisher<[PDFCoreDataModel], Error> in
                XCTAssertFalse(updatedItem.isFavourite)  // Validate toggle worked
                return sut.retrieve()
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Toggling and retrieving succeeded")
                case .failure(let error):
                    XCTFail("Toggle or Retrieve failed: \(error)")
                }
                expectation.fulfill()
            }, receiveValue: { retrievedItems in
                // Assert retrieved data includes the updated item
                
                self.comparePDFData(expectedDatas: [createDummyPDFCoreDataModel(key: "first", isfavorite: false), secondNotFavoritePdfData], actualdata: retrievedItems)
            })
            .store(in: &cancellables)


        wait(for: [expectation], timeout: 5.0)
    }
    
    func test_delete_DeleteData() throws {
        let sut = try makeSUT()
        let firstItem = createDummyPDFCoreDataModel(key: "first", isfavorite: true)
        let secondItem = createDummyPDFCoreDataModel(key: "second", isfavorite: false)

        let expectation = self.expectation(description: "Toggle favorite")

        insert(sut, datas: [firstItem, secondItem])
        
        sut.deletePdfData(pdfItem: firstItem)
            .flatMap { isSuccess -> AnyPublisher<[PDFCoreDataModel], Error> in
                XCTAssertTrue(isSuccess)  // Validate toggle worked
                return sut.retrieve()
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Toggling and retrieving succeeded")
                case .failure(let error):
                    XCTFail("Toggle or Retrieve failed: \(error)")
                }
                expectation.fulfill()
            }, receiveValue: { retrievedItems in
                // Assert retrieved data includes the updated item
                
                self.comparePDFData(expectedDatas: [secondItem], actualdata: retrievedItems)
            })
            .store(in: &cancellables)


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

    func insert(_ sut: PDFLocalDataLoader, datas: [PDFCoreDataModel], file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "waitig for insertion")
        // var isInsertionSuccess = false

        sut.insertPDFDatas(pdfDatas: datas)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Insert completed")
                case let .failure(error):
                    // print("Insert failed with error: \(error)")
                    XCTFail("Insertion failed with error: \(error)")
                }
                exp.fulfill()
            }, receiveValue: { insertedPDFs in
                print("Inserted: \(insertedPDFs.count) new items")

            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

//
//    @discardableResult
//    func retrieve(_ sut: PDFLocalDataLoader, file: StaticString = #filePath, line: UInt = #line) -> [PDFCoreDataModel]? {
//        let exp = expectation(description: "waitig for insertion")
//        var localDatas: [PDFCoreDataModel] = []
//        sut.retrieve { datas in
//            localDatas = datas ?? []
//            exp.fulfill()
//        }
//        wait(for: [exp], timeout: 1.0)
//        return localDatas
//    }

    func expect(_ sut: PDFLocalDataLoader, toRetrieve expectedDatas: [PDFCoreDataModel], file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve()
            .sink(receiveCompletion: { completion in

                switch completion {
                case .finished:
                    print("Insert completed")
                case let .failure(error):
                    // print("Insert failed with error: \(error)")
                    XCTFail("Insertion failed with error: \(error)")
                }
                exp.fulfill()
            }, receiveValue: { datas in
                self.comparePDFData(expectedDatas: expectedDatas, actualdata: datas, file: file, line: line)
                //   print("retr: \(insertedPDFs.count) new items")

            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func comparePDFData(expectedDatas: [PDFCoreDataModel], actualdata: [PDFCoreDataModel], file: StaticString = #file, line: UInt = #line) {
      

        XCTAssertEqual(
            Set(actualdata),
            Set(expectedDatas),
            "Expected data does not match actual data (ignoring order)",
            file: file,
            line: line
        )
    }
}

func createDummyPDFCoreDataModel(pdfTitle: String = "Test PDF", pdfAuthor: String = "John Doe", pdfPageCount: Int = 3, key: String, isfavorite: Bool = false, lastOpenedDate: Date? = nil) -> PDFCoreDataModel {
    let pdfData: Data = createDummyPDF(title: pdfTitle, author: pdfAuthor, pageCount: pdfPageCount).dataRepresentation()!
    return PDFCoreDataModel(key: key, data: pdfData, isFavourite: isfavorite)
}

func createDummyPDF(title: String = "Test PDF", author: String = "John Doe", pageCount: Int = 3) -> PDFDocument {
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

    // Bookmark data is usually created from PDFDocument's data
    return pdfDocument // .dataRepresentation()
}

extension PDFCoreDataModel: Equatable, Hashable {
    public static func == (lhs: PDFCoreDataModel, rhs: PDFCoreDataModel) -> Bool {
        return lhs.key == rhs.key &&
          //  lhs.data == rhs.data &&
            lhs.isFavourite == rhs.isFavourite
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(data)
        hasher.combine(isFavourite)
    }
}

// func getPdfData(pdfDocument : PDFDocument?) -> Data? {
//    return pdfDocument?.dataRepresentation()
// }
