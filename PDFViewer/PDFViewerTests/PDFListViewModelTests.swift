//
//  PDFListViewModelTests.swift
//  PDFViewerTests
//
//  Created by Habibur Rahman on 3/5/25.
//

import Combine
import PDFKit
@testable import PDFViewer
import XCTest

final class PDFListViewModelTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    var viewModel: PDFListViewModel!
    var mockRepository: MockPDFRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockPDFRepository()
        viewModel = PDFListViewModel(repository: mockRepository)
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testLoadPDFs_Success() {
        let expectedPDFs = [createPDFModelData(key: "key_1"), createPDFModelData(key: "key_2")]
        mockRepository.retrieveResult = .success(expectedPDFs)

        let expectation = XCTestExpectation(description: "loadPDFs succeeded")

        viewModel.loadPDFs()
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Expected success but got failure: \(error)")
                }
            }, receiveValue: { [weak self] models in
               
                XCTAssertEqual(models, expectedPDFs)
                XCTAssertEqual(self?.viewModel.allPdfModels, expectedPDFs)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func testImportPDFs_Success() {
        mockRepository.insertResult = .success(true)
        let sampleURL = URL(fileURLWithPath: "/fake/path/sample.pdf")

        let expectedPDFs = [createPDFModelData(key: "key_1"), createPDFModelData(key: "key_2")]
        mockRepository.retrieveResult = .success(expectedPDFs)

        let expectation = XCTestExpectation(description: "Import succeeded")

        viewModel.importPDFs(urls: [sampleURL])
            .flatMap { [weak viewModel] _ -> AnyPublisher<[PDFModelData], Error> in
                guard let viewModel = viewModel else {
                    return Fail(error: MockError.test).eraseToAnyPublisher()
                }
                return viewModel.loadPDFs()
            }
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    XCTFail("Expected success, got failure: \(error)")
                }
            }, receiveValue: { [weak viewModel] _ in
                XCTAssertEqual(viewModel?.allPdfModels, expectedPDFs)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }
    
    func test_ToggleFavorite_UpdatesFavoriteAndViewModel() {
        // Arrange
        let firstPDF = createPDFModelData(key: "key_1", isFavorite: false)
        let secondPDF = createPDFModelData(key: "key_2", isFavorite: false)
        viewModel.allPdfModels = [firstPDF, secondPDF]

        var expectedUpdatedPDF = firstPDF
        expectedUpdatedPDF.toggleFavorite()
        mockRepository.updateResult = .success(expectedUpdatedPDF)

        let expectation = expectation(description: "toggleFavorite completed")

        // Act
        viewModel.toggleFavorite(for: firstPDF)

        // Assert
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.allPdfModels, [expectedUpdatedPDF, secondPDF])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}

class MockPDFRepository: PDFRepositoryProtocol {
    var insertResult: Result<Bool, Error> = .success(true)
    var retrieveResult: Result<[PDFModelData], Error> = .success([])
    var updateResult: Result<PDFModelData, Error>? // = .success(true)
    var deleteResult: Result<Bool, Error> = .success(true)

    func insert(pdfDatas: [PDFModelData]) -> AnyPublisher<Bool, any Error> {
        return insertResult.publisher.eraseToAnyPublisher()
    }

    func retrieve() -> AnyPublisher<[PDFModelData], any Error> {
        return retrieveResult.publisher.eraseToAnyPublisher()
    }

    func update(updatedPdfData: PDFViewer.PDFModelData) -> AnyPublisher<PDFModelData, any Error> {
        return updateResult!.publisher.eraseToAnyPublisher()
    }

    func delete(pdfKey: String) -> AnyPublisher<Bool, any Error> {
        return deleteResult.publisher.eraseToAnyPublisher()
    }
}

enum MockError: Error {
    case test
}

extension MockError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .test: return "Test Error"
        }
    }
}

//
