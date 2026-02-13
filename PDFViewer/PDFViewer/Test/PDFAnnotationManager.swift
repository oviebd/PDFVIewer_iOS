//
//  PDFAnnotationManager.swift
//  PDFViewer
//
//  Created by Habibur_Periscope on 3/2/26.
//

import PDFKit
import PencilKit
import SwiftUI

// MARK: - Annotation Manager

class PDFAnnotationManager {
    static var annotationsCache: [String: [Int: Data]] = [:]

    private func getCacheKey(for url: URL) -> String {
        return url.lastPathComponent
    }

    // MARK: - Annotation Persistence (Core Data)

    /// Serialize cached drawings into binary Data for DB storage
    func getSerializedAnnotations(for pdfURL: URL) -> Data? {
        let key = getCacheKey(for: pdfURL)
        guard let pageData = PDFAnnotationManager.annotationsCache[key], !pageData.isEmpty else {
            return nil
        }

        var annotationsDict: [String: String] = [:]
        for (pageIndex, data) in pageData {
            annotationsDict["page_\(pageIndex)"] = data.base64EncodedString()
        }

        do {
            return try JSONSerialization.data(withJSONObject: annotationsDict)
        } catch {
            debugPrint("❌ Serialization error: \(error)")
            return nil
        }
    }

    /// Load annotations from binary Data into memory cache
    func loadAnnotations(from data: Data?, for pdfURL: URL) {
        // Hydrate or refresh cache from binary data
        let key = getCacheKey(for: pdfURL)
        guard let data = data,
              let annotationsDict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            PDFAnnotationManager.annotationsCache[key] = [:]
            return
        }

        var pageDataMap: [Int: Data] = [:]
        for (pageKey, base64String) in annotationsDict {
            if let pageIndexStr = pageKey.split(separator: "_").last,
               let pageIndex = Int(pageIndexStr),
               let drawingData = Data(base64Encoded: base64String) {
                pageDataMap[pageIndex] = drawingData
            }
        }
        PDFAnnotationManager.annotationsCache[key] = pageDataMap
    }

    /// Legacy support or helper to sync active views before DB save
    func syncViewsToCache(canvasViews: [Int: PKCanvasView], pdfURL: URL) {
        let key = getCacheKey(for: pdfURL)
        if PDFAnnotationManager.annotationsCache[key] == nil {
            PDFAnnotationManager.annotationsCache[key] = [:]
        }
        for (pageIndex, canvasView) in canvasViews {
            if let data = try? canvasView.drawing.dataRepresentation() {
                PDFAnnotationManager.annotationsCache[key]?[pageIndex] = data
            }
        }
    }

    /// Get drawing for a specific page from cache
    func getDrawing(for pageIndex: Int, pdfURL: URL) -> PKDrawing? {
        let key = getCacheKey(for: pdfURL)
        guard let pageData = PDFAnnotationManager.annotationsCache[key]?[pageIndex] else {
            return nil
        }
        return try? PKDrawing(data: pageData)
    }

    /// Helper to update a single page in cache (used during live editing)
    func updateCache(for pageIndex: Int, canvasView: PKCanvasView, pdfURL: URL) {
        let key = getCacheKey(for: pdfURL)
        if PDFAnnotationManager.annotationsCache[key] == nil {
            PDFAnnotationManager.annotationsCache[key] = [:]
        }
        if let data = try? canvasView.drawing.dataRepresentation() {
            PDFAnnotationManager.annotationsCache[key]?[pageIndex] = data
        }
    }

    func exportFlattenedPDF(
        pdfDocument: PDFDocument,
        canvasViews: [Int: PKCanvasView],
        originalURL: URL
    ) -> URL? {
        // Get Documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("❌ Could not access documents directory")
            return nil
        }

        // Create "AnnotatedPDFs" subdirectory
        let annotatedDirectory = documentsDirectory.appendingPathComponent("AnnotatedPDFs", isDirectory: true)

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: annotatedDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: annotatedDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                debugPrint("❌ Failed to create directory: \(error)")
                return nil
            }
        }

        // Generate unique filename with timestamp
        let pdfName = originalURL.deletingPathExtension().lastPathComponent
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "\(pdfName)_annotated_\(timestamp).pdf"
        let outputURL = annotatedDirectory.appendingPathComponent(fileName)

        // Remove file if it already exists
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        let format = UIGraphicsPDFRendererFormat()
        guard let firstPage = pdfDocument.page(at: 0) else { return nil }
        let firstPageBounds = firstPage.bounds(for: .mediaBox)

        let renderer = UIGraphicsPDFRenderer(bounds: firstPageBounds, format: format)

        do {
            try renderer.writePDF(to: outputURL) { context in
                for pageIndex in 0 ..< pdfDocument.pageCount {
                    guard let page = pdfDocument.page(at: pageIndex) else { continue }

                    let pageBounds = page.bounds(for: .mediaBox)
                    context.beginPage(withBounds: pageBounds, pageInfo: [:])

                    guard let ctx = UIGraphicsGetCurrentContext() else { continue }

                    // Draw PDF page
                    ctx.saveGState()
                    ctx.translateBy(x: 0, y: pageBounds.height)
                    ctx.scaleBy(x: 1.0, y: -1.0)
                    page.draw(with: .mediaBox, to: ctx)
                    ctx.restoreGState()

                    // Draw PencilKit annotations on top
                    if let canvasView = canvasViews[pageIndex] {
                        let drawing = canvasView.drawing
                        if !drawing.bounds.isEmpty {
                            let image = drawing.image(from: pageBounds, scale: 1.0)
                            image.draw(in: pageBounds)
                        }
                    } else if let cachedDrawing = getDrawing(for: pageIndex, pdfURL: originalURL) {
                        if !cachedDrawing.bounds.isEmpty {
                            let image = cachedDrawing.image(from: pageBounds, scale: 1.0)
                            image.draw(in: pageBounds)
                        }
                    }
                }
            }
            debugPrint("✅ Flattened PDF saved to: \(outputURL.path)")
            return outputURL
        } catch {
            debugPrint("❌ Error creating flattened PDF: \(error)")
            return nil
        }
    }
}

// MARK: - Extension to PDFAnnotation for Image Stamp

extension PDFAnnotation {
    func setImageAsStamp(_ image: UIImage) {
        if let imageData = image.pngData() {
            // This is a workaround - PDF annotations don't directly support images
            // We'll use appearance stream
            setValue(imageData, forAnnotationKey: .appearanceDictionary)
        }
    }
}
