//
//  PDFKeyGenerator.swift
//  PDFViewer
//
//  Created by Habibur_Periscope on 5/7/25.
//

import Foundation
import PDFKit
import CryptoKit

final class PDFKeyGenerator {
    
    // MARK: - Singleton (Optional)
    static let shared = PDFKeyGenerator()
    private init() {}

    // MARK: - Public Key Generation (Async)
    func generateKey(for url: URL, maxPages: Int = 10, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let key = self.computeKey(url: url, maxPages: maxPages)
            DispatchQueue.main.async {
                completion(key)
            }
        }
    }

    // MARK: - Private Key Logic
    func computeKey(url: URL, maxPages: Int) -> String? {
        guard let pdfDocument = PDFDocument(url: url) else { return nil }

        var combinedText = ""

        // Extract metadata
        if let title = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String {
            combinedText += title
        }

        if let author = pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String {
            combinedText += author
        }

        if let creationDate = pdfDocument.documentAttributes?[PDFDocumentAttribute.creationDateAttribute] as? Date {
            combinedText += creationDate.description
        }

        // Extract partial text (first N pages)
        let scanCount = min(pdfDocument.pageCount, maxPages)
        for index in 0..<scanCount {
            if let pageText = pdfDocument.page(at: index)?.string {
                combinedText += pageText
            }
        }

        guard !combinedText.isEmpty else { return nil }

        // Generate SHA256 hash
        let hash = SHA256.hash(data: Data(combinedText.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
