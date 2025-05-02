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
        let sampleModel = makeSamplePDFCoreDataModel()
        store.insertResult = .success([sampleModel])

        let expectation = self.expectation(description: "Insert")

        repository.insert(pdfDatas: [sampleModel])
            .sink(receiveCompletion: { _ in },
                  receiveValue: { result in
                      XCTAssertEqual(result.first?.pdfKey, sampleModel.key)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_RetrieveSuccess() {
        let sampleModel = makeSamplePDFCoreDataModel()
        store.retrieveResult = .success([sampleModel])

        let expectation = self.expectation(description: "Retrieve")

        repository.retrieve()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { result in
                      XCTAssertEqual(result.first?.pdfKey, sampleModel.key)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func testToggleFavoriteSuccess() {
        let sampleModel = makeSamplePDFCoreDataModel()
        store.updateResult = .success(true)

        let expectation = self.expectation(description: "ToggleFavorite")

        repository.toggleFavorite(pdfItem: sampleModel)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { result in
                      XCTAssertEqual(result.pdfKey, sampleModel.key)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func testDeleteSuccess() {
        let sampleModel = makeSamplePDFCoreDataModel()
        store.deleteResult = .success(true)

        let expectation = self.expectation(description: "Delete")

        repository.delete(pdfItem: sampleModel)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { result in
                      XCTAssertTrue(result)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // Helpers
    func makeSamplePDFCoreDataModel() -> PDFCoreDataModel {
        let dummyURL = URL(fileURLWithPath: "/dev/null")
        let bookmarkData = try! dummyURL.bookmarkData()
        return PDFCoreDataModel(key: "testKey", data: bookmarkData, isFavourite: false)
    }
}

final class MockPDFLocalDataStore: PDFLocalDataStore {
    var insertResult: Result<[PDFCoreDataModel], Error> = .success([])
    var retrieveResult: Result<[PDFCoreDataModel], Error> = .success([])
    var updateResult: Result<Bool, Error> = .success(true)
    var deleteResult: Result<Bool, Error> = .success(true)

    override func insert(pdfDatas: [PDFCoreDataModel]) -> AnyPublisher<[PDFCoreDataModel], Error> {
        return insertResult.publisher.eraseToAnyPublisher()
    }

    override func retrieve() -> AnyPublisher<[PDFCoreDataModel], Error> {
        return retrieveResult.publisher.eraseToAnyPublisher()
    }

    override func update(updatedData: PDFCoreDataModel) -> AnyPublisher<Bool, Error> {
        return updateResult.publisher.eraseToAnyPublisher()
    }

    override func delete(updatedData: PDFCoreDataModel) -> AnyPublisher<Bool, Error> {
        return deleteResult.publisher.eraseToAnyPublisher()
    }
}
