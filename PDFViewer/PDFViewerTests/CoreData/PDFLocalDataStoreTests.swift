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

    func test_update_Success() throws {
        let sut = try makeSUT()
        let firstItem = createDummyPDFCoreDataModel(key: "first", isfavorite: true)
        let secondItem = createDummyPDFCoreDataModel(key: "second", isfavorite: false)
        let firstUpdatedItem = firstItem
        firstUpdatedItem.isFavourite = false
    
        

        insertAndAssert(
            sut: sut,
            insertItems: [firstItem, secondItem],
            expectedItems: [firstUpdatedItem, secondItem]
        ) {
            sut.update(updatedData: firstUpdatedItem)
                .flatMap { updatedData -> AnyPublisher<[PDFCoreDataModel], Error> in
                    XCTAssertFalse(updatedData.isFavourite)
                    return sut.retrieve()
                }
                .eraseToAnyPublisher()
        }
    }
    
    func test_delete_DeleteData() throws {
        let sut = try makeSUT()
        let firstItem = createDummyPDFCoreDataModel(key: "first", isfavorite: true)
        let secondItem = createDummyPDFCoreDataModel(key: "second", isfavorite: false)
        
        insertAndAssert(
            sut: sut,
            insertItems: [firstItem, secondItem],
            expectedItems: [secondItem]
        ) {
            sut.delete(pdfKey: firstItem.key)
                .flatMap { isSuccess -> AnyPublisher<[PDFCoreDataModel], Error> in
                    XCTAssertTrue(isSuccess)
                    return sut.retrieve()
                }
                .eraseToAnyPublisher()
        }
    }

    // Helpers
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> PDFLocalDataStore {
        let sut = try PDFLocalDataStore(storeURL: inMemoryStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func inMemoryStoreURL() -> URL {
        URL(fileURLWithPath: "/dev/null")
            .appendingPathComponent("\(type(of: self)).store")
    }
    
    private func insertAndAssert(
        sut: PDFLocalDataStore,
        insertItems: [PDFCoreDataModel],
        expectedItems: [PDFCoreDataModel],
        action: @escaping () -> AnyPublisher<[PDFCoreDataModel], Error>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = self.expectation(description: "Action expectation")
        
        insert(sut, datas: insertItems)

        action()
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Operation failed: \(error)", file: file, line: line)
                }
                expectation.fulfill()
            }, receiveValue: { retrievedItems in
                self.comparePDFDCoreDataModel(expectedDatas: expectedItems, actualdata: retrievedItems)
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 5.0)
    }

    func insert(_ sut: PDFLocalDataStore, datas: [PDFCoreDataModel], file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "waitig for insertion")
        // var isInsertionSuccess = false

        sut.insert(pdfDatas: datas)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Insert completed")
                case let .failure(error):
                    // print("Insert failed with error: \(error)")
                    XCTFail("Insertion failed with error: \(error)")
                }
                exp.fulfill()
            }, receiveValue: { isSuccess in
                print("Inserted: \(isSuccess) new items")

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

    func expect(_ sut: PDFLocalDataStore, toRetrieve expectedDatas: [PDFCoreDataModel], file: StaticString = #file, line: UInt = #line) {
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
                self.comparePDFDCoreDataModel(expectedDatas: expectedDatas, actualdata: datas, file: file, line: line)
                //   print("retr: \(insertedPDFs.count) new items")

            })
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }

    func comparePDFDCoreDataModel(expectedDatas: [PDFCoreDataModel], actualdata: [PDFCoreDataModel], file: StaticString = #file, line: UInt = #line) {
      

        XCTAssertEqual(
            Set(actualdata),
            Set(expectedDatas),
            "Expected data does not match actual data (ignoring order)",
            file: file,
            line: line
        )
    }
}


// func getPdfData(pdfDocument : PDFDocument?) -> Data? {
//    return pdfDocument?.dataRepresentation()
// }
