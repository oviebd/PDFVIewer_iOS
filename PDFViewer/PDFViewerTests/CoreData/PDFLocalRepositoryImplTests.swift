//
//  PDFLocalRepositoryImplTests.swift
//  PDFViewerTests
//
//  Created by Habibur Rahman on 2/5/25.
//

import Combine
import Foundation
@testable import PDFViewer
import XCTest

final class PDFLocalRepositoryImplTests: XCTestCase {
    var repository: PDFLocalRepositoryImpl!
    var store: MockPDFLocalDataStore!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        store = try? MockPDFLocalDataStore()
        repository = PDFLocalRepositoryImpl(store: store)
        cancellables = []
    }

    override func tearDown() {
        store = nil
        repository = nil
        cancellables = nil
        super.tearDown()
    }

    func test_InsertSuccess() {
        let sampleModel = createDummyPDFModelData(key: "test_1", isFavorite: true)
        store.insertResult = .success(true)

        let expectation = self.expectation(description: "Insert")

        repository.insert(pdfDatas: [sampleModel])
            .sink(receiveCompletion: { completion in
                      switch completion {
                      case .finished:
                          break // success
                      case let .failure(error):
                          XCTFail("Insertion failed with error: \(error)")
                      }
                  },
                  receiveValue: { result in
                      XCTAssertEqual(result, true)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_RetrieveSuccess() {
        let sampleModel = createDummyPDFCoreDataModel(key: "test_1")
        store.retrieveResult = .success([sampleModel])

        let expectation = self.expectation(description: "Retrieve")

        repository.retrieve()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { result in
                      XCTAssertEqual(result.first?.key, sampleModel.key)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_update_Success() {
        let sampleModel = createDummyPDFModelData(key: "key_1", isFavorite: false)
        let updatedData = sampleModel
        updatedData.isFavorite = true

        store.updateResult = .success(updatedData.toCoereDataModel())

        let expectation = self.expectation(description: "update Fav Data")

        repository.update(updatedPdfData: updatedData)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { result in
                      XCTAssertEqual(result.key, sampleModel.key)
                      XCTAssertEqual(result.isFavorite, updatedData.isFavorite)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func testDeleteSuccess() {
        store.deleteResult = .success(true)
        let expectation = self.expectation(description: "Delete")

        repository.delete(pdfKey: "test_1")
            .sink(receiveCompletion: { _ in },
                  receiveValue: { isSuccess in
                      XCTAssertTrue(isSuccess)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // Helpers

    func createDummyPDFModelData(key: String, isFavorite: Bool) -> PDFModelData {
        let dummyURL = URL(fileURLWithPath: "/dev/null")
        let bookmarkData = try! dummyURL.bookmarkData()
        // return PDFCoreDataModel(key: "testKey", bookmarkData: bookmarkData, isFavourite: false, lastOpenPage: 0, lastOpenTime: nil)
        return PDFModelData(key: key, bookmarkData: bookmarkData, isFavorite: isFavorite, lastOpenedPage: 0, lastOpenTime: nil)
    }
}

final class MockPDFLocalDataStore: PDFLocalDataStore {
    var insertResult: Result<Bool, Error> = .success(true)
    var retrieveResult: Result<[PDFCoreDataModel], Error> = .success([])
    var updateResult: Result<PDFCoreDataModel, Error>? // = .success(true)
    var deleteResult: Result<Bool, Error> = .success(true)

    override func insert(pdfDatas: [PDFCoreDataModel]) -> AnyPublisher<Bool, Error> {
        return insertResult.publisher.eraseToAnyPublisher()
    }

    override func retrieve() -> AnyPublisher<[PDFCoreDataModel], Error> {
        return retrieveResult.publisher.eraseToAnyPublisher()
    }

    override func update(updatedData: PDFCoreDataModel) -> AnyPublisher<PDFCoreDataModel, Error> {
        return updateResult!.publisher.eraseToAnyPublisher()
    }

    override func delete(pdfKey: String) -> AnyPublisher<Bool, Error> {
        return deleteResult.publisher.eraseToAnyPublisher()
    }
}
