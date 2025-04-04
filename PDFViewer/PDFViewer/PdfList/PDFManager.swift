//
//  PDFManager.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 4/4/25.
//

import Foundation
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct PDFFile: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let metadata : PDFMetadata
}

struct PDFMetadata {
    let image: UIImage?
    let author: String
    let title: String
}




class PDFManager: ObservableObject {
    @Published var pdfFiles: [PDFFile] = []

    func fetchPDFFiles(from folderURL: URL) {
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            let pdfs = files.filter { $0.pathExtension.lowercased() == "pdf" }
                .map { PDFFile(name: $0.lastPathComponent, url: $0, metadata: extractPDFMetadata(from: $0)) }

            DispatchQueue.main.async {
                self.pdfFiles = pdfs
            }
        } catch {
            print("Error fetching PDFs: \(error)")
        }
    }
    func extractPDFMetadata(from url: URL) -> PDFMetadata {
        guard let pdfDocument = PDFDocument(url: url) else {
            return PDFMetadata(image: nil, author: "Unknown", title: url.lastPathComponent)
        }
        
        // 🖼 Extract first page as image
        let page = pdfDocument.page(at: 0)
        let image = page?.thumbnail(of: CGSize(width: 100, height: 140), for: .cropBox)
        
        // 📖 Extract metadata
        let author = pdfDocument.documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String ?? "Unknown"
        let title = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? url.lastPathComponent
        
        return PDFMetadata(image: image, author: author, title: title)
    }
}
