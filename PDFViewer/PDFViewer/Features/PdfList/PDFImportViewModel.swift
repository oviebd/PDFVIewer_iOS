//
//  PDFImportViewModel.swift
//  PDFViewer
//
//  Created by Antigravity on 8/2/26.
//

import Foundation
import Combine
import SwiftUI

enum ImportStatus: Equatable {
    case pending
    case importing
    case success
    case failed(String)
    case duplicate
    
    var iconName: String {
        switch self {
        case .pending: return "circle"
        case .importing: return "arrow.down.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .duplicate: return "exclamationmark.triangle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .pending: return .gray
        case .importing: return .blue
        case .success: return .green
        case .failed: return .red
        case .duplicate: return .orange
        }
    }
}

struct ImportItem: Identifiable {
    let id = UUID()
    var fileName: String
    let bookmarkData: BookmarkDataClass
    var status: ImportStatus = .pending
}

final class PDFImportViewModel: ObservableObject {
    @Published var importItems: [ImportItem] = []
    @Published var isImporting = false
    @Published var isCompleted = false
    @Published var isCancelled = false
    @Published var currentlyImportingItem: ImportItem?
    
    private let repository: PDFRepositoryProtocol
    private let existingKeys: Set<String>
    private var cancellables = Set<AnyCancellable>()
    
    private var importedModels: [PDFModelData] = []
    var onCompletion: (([PDFModelData]) -> Void)?
    
    func cancelImport() {
        guard isImporting && !isCompleted && !isCancelled else { return }
        isCancelled = true
        isImporting = false
        currentlyImportingItem = nil
    }
    
    var successCount: Int {
        importItems.filter { $0.status == .success }.count
    }
    
    var totalCount: Int {
        importItems.count
    }
    
    init(bookmarkDatas: [BookmarkDataClass], repository: PDFRepositoryProtocol, existingKeys: Set<String>) {
        self.repository = repository
        self.existingKeys = existingKeys
        self.importItems = bookmarkDatas.map { data in
            // Initial placeholder, name will be resolved during sequential import
            return ImportItem(fileName: "Pending...", bookmarkData: data)
        }
    }
    
    func startImport() {
        guard !isImporting && !isCompleted else { return }
        isImporting = true
        
        importNext(index: 0)
    }
    
    private func importNext(index: Int) {
        guard index < importItems.count else {
            DispatchQueue.main.async { [weak self] in
                self?.isImporting = false
                self?.isCompleted = true
                self?.currentlyImportingItem = nil
                if let models = self?.importedModels {
                    self?.onCompletion?(models)
                }
            }
            return
        }
        
        // Use a background queue for heavy lifting but process one at a time
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if self.isCancelled { return }
            
            let item = self.importItems[index]
            
            // 1. Resolve filename if not already resolved
            let fileName = self.resolveFileNameSafely(from: item.bookmarkData.data) ?? "PDF File"
            
            DispatchQueue.main.async {
                self.importItems[index].fileName = fileName
                self.updateStatus(index: index, status: .importing)
            }
            
            // 2. Check for duplicate
            if self.existingKeys.contains(item.bookmarkData.key) {
                print("Skipping duplicate: \(item.bookmarkData.key)")
                DispatchQueue.main.async {
                    self.updateStatus(index: index, status: .duplicate)
                    self.importNextWithDelay(index: index + 1)
                }
                return
            }
            
            // 3. Perform heavy PDF data extraction
            let model = PDFModelData(
                key: item.bookmarkData.key,
                bookmarkData: item.bookmarkData.data,
                annotationdata: nil,
                isFavorite: false,
                lastOpenedPage: 0,
                lastOpenTime: nil
            )
            
            // 4. Save to repository
            DispatchQueue.main.async {
                self.repository.insert(pdfDatas: [model])
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { [weak self] completion in
                        if self?.isCancelled == true { return }
                        if case let .failure(error) = completion {
                            self?.updateStatus(index: index, status: .failed(error.localizedDescription))
                            self?.importNextWithDelay(index: index + 1)
                        }
                    }, receiveValue: { [weak self] success in
                        if self?.isCancelled == true { return }
                        if success {
                            self?.importedModels.append(model)
                            self?.updateStatus(index: index, status: .success)
                        } else {
                            self?.updateStatus(index: index, status: .failed("Database insertion failed"))
                        }
                        self?.importNextWithDelay(index: index + 1)
                    })
                    .store(in: &self.cancellables)
            }
        }
    }
    
    private func resolveFileNameSafely(from data: Data) -> String? {
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            // Ensure we have access even just for the file name if it's security scoped
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                return url.lastPathComponent
            } else {
                // Fallback to name even if security access fails (sometimes works for name)
                return url.lastPathComponent
            }
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }
    
    private func importNextWithDelay(index: Int) {
        if isCancelled { return }
        // Reduced delay to keep it fast but still visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard self?.isCancelled == false else { return }
            self?.importNext(index: index)
        }
    }
    
    private func updateStatus(index: Int, status: ImportStatus) {
        // Ensure index is still valid (in case items were cleared or deinit is happening)
        guard index < importItems.count else { return }
        
        self.importItems[index].status = status
        if status == .importing {
            self.currentlyImportingItem = self.importItems[index]
        }
    }
}
