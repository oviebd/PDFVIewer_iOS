//
//  PDFKeyGeneratorTests.swift
//  PDFViewerTests
//
//  Created by Habibur_Periscope on 5/7/25.
//

import XCTest
import PDFKit

@testable import PDFViewer // Replace with your module name

final class PDFKeyGeneratorTests: XCTestCase {
    
   
    // Test case 1: Same content in two locations generates same key
    func testSamePDFContentDifferentURLGeneratesSameKey() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url1 = tempDir.appendingPathComponent("sample1.pdf")
        let url2 = tempDir.appendingPathComponent("sample2.pdf")
        
        try createTestPDF(at: url1, text: "Hello, same PDF content", title: "Doc A")
        try createTestPDF(at: url2, text: "Hello, same PDF content", title: "Doc A")

        let key1 = PDFKeyGenerator.shared.computeKey(url: url1, maxPages: 10)
        let key2 = PDFKeyGenerator.shared.computeKey(url: url2, maxPages: 10)

        XCTAssertEqual(key1, key2, "Keys should be same for identical content")
    }

    // Test case 2: Different content generates different key
    func testDifferentPDFContentGeneratesDifferentKey() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url1 = tempDir.appendingPathComponent("doc1.pdf")
        let url2 = tempDir.appendingPathComponent("doc2.pdf")
        
        try createTestPDF(at: url1, text: "Hello World", title: "Doc One")
        try createTestPDF(at: url2, text: "Goodbye World", title: "Doc Two")

        let key1 = PDFKeyGenerator.shared.computeKey(url: url1, maxPages: 10)
        let key2 = PDFKeyGenerator.shared.computeKey(url: url2, maxPages: 10)

        XCTAssertNotEqual(key1, key2, "Keys should differ for different content")
    }

    // Test case 3: Same file name, different content → different keys
    func testSameFileNameDifferentContentGeneratesDifferentKey() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let url1 = tempDir.appendingPathComponent("sameName.pdf")
        let url2 = tempDir.appendingPathComponent("sameName_copy.pdf")

        try createTestPDF(at: url1, text: "First PDF Content")
        try createTestPDF(at: url2, text: "Second PDF Content")

        let key1 = PDFKeyGenerator.shared.computeKey(url: url1, maxPages: 10)
        let key2 = PDFKeyGenerator.shared.computeKey(url: url2, maxPages: 10)

        XCTAssertNotEqual(key1, key2, "PDFs with same name but different content should have different keys")
    }
    
    
    
    // Helper to generate test PDF at a given URL with custom text and title
    func createTestPDF(at url: URL, text: String, title: String? = nil) throws {
        _ = PDFDocument()
        _ = PDFPage()
        let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard A4
        
        // Add text content to page
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraph
            ]
            text.draw(in: CGRect(x: 20, y: 20, width: 572, height: 752), withAttributes: attributes)
        }

        try data.write(to: url)

        // Add title metadata (optional)
        let writtenDoc = PDFDocument(url: url)
        if let title = title {
            writtenDoc?.documentAttributes = [PDFDocumentAttribute.titleAttribute: title]
            writtenDoc?.write(to: url)
        }
    }

}
