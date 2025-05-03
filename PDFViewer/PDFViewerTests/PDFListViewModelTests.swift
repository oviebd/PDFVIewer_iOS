//
//  PDFListViewModelTests.swift
//  PDFViewerTests
//
//  Created by Habibur Rahman on 3/5/25.
//

import Combine
@testable import PDFViewer
import XCTest
import PDFKit



final class PDFListViewModelTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    func test_loadPDFs_successfullyUpdatesModels() {
        let expectedPDFs = [
            PDFFile(name: "A", url: URL(fileURLWithPath: "/A"), metadata: .init(image: nil, author: "X", title: "A"), pdfKey: "key1")
        ]
        let mockRepo = MockPDFRepository()
        mockRepo.retrieveResult = .success(expectedPDFs)

        let viewModel = PDFListViewModel(repository: mockRepo)

        let expectation = self.expectation(description: "Loading PDFs")

        viewModel.$pdfModels
            .dropFirst()
            .sink { models in
                XCTAssertEqual(models.count, expectedPDFs.count)
              //  XCTAssertEqual(models, expectedPDFs)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_loadPDFs_handlesError() {
        let mockRepo = MockPDFRepository()
        mockRepo.retrieveResult = .failure(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load"]))

        let viewModel = PDFListViewModel(repository: mockRepo)

        let expectation = self.expectation(description: "Error handled")

        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertEqual(errorMessage, "Failed to load")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_toggleFavorite_updatesModel() {
        let originalModel = PDFFile(name: "B", url: URL(fileURLWithPath: "/B"), metadata: .init(image: nil, author: "Y", title: "B"), pdfKey: "key2")
        let updatedModel = PDFFile(name: "B", url: URL(fileURLWithPath: "/B"), metadata: .init(image: nil, author: "Y", title: "B"), pdfKey: "key2")

        let mockRepo = MockPDFRepository()
        mockRepo.toggleFavoriteResult = .success(updatedModel)

        let viewModel = PDFListViewModel(repository: mockRepo)
        viewModel.pdfModels = [originalModel]

        let expectation = self.expectation(description: "Favorite toggled")

        viewModel.$pdfModels
            .dropFirst()
            .sink { models in
                XCTAssertEqual(models.first?.pdfKey, updatedModel.pdfKey)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let dummyCoreDataModel = PDFCoreDataModel(key: "key2", data: Data(), isFavourite: false)
        viewModel.toggleFavorite(for: dummyCoreDataModel)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func test_importPDFs_succeeds() {
        let mockRepo = MockPDFRepository()
        mockRepo.insertResult = .success([
            PDFFile(name: "C", url: URL(fileURLWithPath: "/C"), metadata: .init(image: nil, author: "Z", title: "C"), pdfKey: "key3")
        ])

        let viewModel = PDFListViewModel(repository: mockRepo)

        let dummyURL = URL(fileURLWithPath: "/path/to/fake.pdf")
        let pdfData = Data()//try! dummyURL.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        let dummyModel = PDFCoreDataModel(key: "key3", data: pdfData, isFavourite: false)

        let expectation = self.expectation(description: "PDF import")

        viewModel.importPDFs(urls: [dummyURL])
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTFail("Expected success")
                }
                expectation.fulfill()
            }, receiveValue: { })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1, handler: nil)
    }
}



final class MockPDFRepository: PDFRepositoryProtocol {
    var retrieveResult: Result<[PDFFile], Error> = .success([])
    var toggleFavoriteResult: Result<PDFFile, Error> = .success(
        PDFFile(name: "Test", url: URL(fileURLWithPath: ""), metadata: PDFMetadata(image: nil, author: "Test", title: "Test"), pdfKey: "test")
    )
    var insertResult: Result<[PDFFile], Error> = .success([])

    func retrieve() -> AnyPublisher<[PDFFile], Error> {
        return retrieveResult.publisher.eraseToAnyPublisher()
    }

    func toggleFavorite(pdfItem: PDFCoreDataModel) -> AnyPublisher<PDFFile, Error> {
        return toggleFavoriteResult.publisher.eraseToAnyPublisher()
    }

    func insert(pdfDatas: [PDFCoreDataModel]) -> AnyPublisher<[PDFFile], Error> {
        return insertResult.publisher.eraseToAnyPublisher()
    }

    func delete(pdfItem: PDFCoreDataModel) -> AnyPublisher<Bool, Error> {
        Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
