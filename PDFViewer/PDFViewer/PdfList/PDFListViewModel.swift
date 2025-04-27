//
//  PDFListViewModel.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 27/4/25.
//

import Foundation
import Combine


final class PDFListViewModel: ObservableObject {
    @Published private(set) var pdfFiles: [PDFFile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: PDFRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: PDFRepository) {
        self.repository = repository
    }
    
    func loadPDFs() {
        isLoading = true
        repository.fetchPDFs()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] files in
                self?.pdfFiles = files
            })
            .store(in: &cancellables)
    }
    
    func importPDFs(urls: [URL]) {
        isLoading = true
        repository.importPDFs(urls: urls)
            .flatMap { [weak self] _ in
                self?.repository.fetchPDFs() ?? Empty().eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] files in
                self?.pdfFiles = files
            })
            .store(in: &cancellables)
    }
}
