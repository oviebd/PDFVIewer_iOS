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
    
    func loadSelectedPDFFiles(urls: [URL]) {
        DispatchQueue.global(qos: .userInitiated).async {

            let pdfs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
                .map { PDFFile(name: $0.lastPathComponent, url: $0, metadata: self.extractPDFMetadata(from: $0))}
            
            DispatchQueue.main.async {
                self.pdfFiles = pdfs
                self.savePDFBookmarks(urls: urls)
            }
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
    
    
    func restorePDFsFromBookmarks() async {
        guard let bookmarkDataArray = UserDefaults.standard.array(forKey: "SavedPDFBookmarks") as? [Data] else { return }

        var restoredPDFs: [PDFFile] = []

        for bookmarkData in bookmarkDataArray {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: [],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                let metadata = extractPDFMetadata(from: url)
                restoredPDFs.append(PDFFile(name: url.lastPathComponent, url: url, metadata: metadata))

            } catch {
                print("❌ Failed to resolve bookmark: \(error)")
            }
        }

        // ✅ Fix: assign to a `let` copy before calling `await`
        let finalPDFs = restoredPDFs

        await MainActor.run {
            self.pdfFiles = finalPDFs
        }
    }

    func savePDFBookmarks(urls: [URL]) {
        var savedBookmarks: [Data] = []

        // Step 1: Load existing bookmarks if any
        if let existing = UserDefaults.standard.array(forKey: "SavedPDFBookmarks") as? [Data] {
            savedBookmarks = existing
        }

        // Step 2: Convert new URLs to bookmark data
        for url in urls {
            do {
                let bookmark = try url.bookmarkData(
                    options: [],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                
                // Avoid duplicate bookmarks
                if !savedBookmarks.contains(bookmark) {
                    savedBookmarks.append(bookmark)
                }

            } catch {
                print("❌ Error creating bookmark for \(url): \(error)")
            }
        }

        // Step 3: Save combined data back to UserDefaults
        UserDefaults.standard.set(savedBookmarks, forKey: "SavedPDFBookmarks")
    }
}
