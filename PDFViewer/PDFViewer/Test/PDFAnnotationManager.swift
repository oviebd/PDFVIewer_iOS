//
//  PDFAnnotationManager.swift
//  PDFViewer
//
//  Created by Habibur_Periscope on 3/2/26.
//


import SwiftUI
import PDFKit
import PencilKit

// MARK: - Annotation Manager
class PDFAnnotationManager {
    static var annotationsCache: [URL: [Int: Data]] = [:]
    
    // MARK: - Annotation Persistence
    
    /// Save PencilKit drawings as separate data (JSON Sidecar)
    @discardableResult
    func saveAnnotationsData(canvasViews: [Int: PKCanvasView], pdfURL: URL) -> URL? {
        // 1. Sync active views to cache
        if PDFAnnotationManager.annotationsCache[pdfURL] == nil {
            PDFAnnotationManager.annotationsCache[pdfURL] = [:]
        }
        
        for (pageIndex, canvasView) in canvasViews {
            if let data = try? canvasView.drawing.dataRepresentation() {
                PDFAnnotationManager.annotationsCache[pdfURL]?[pageIndex] = data
            }
        }
        
        // 2. Prepare data for serialization
        guard let pageData = PDFAnnotationManager.annotationsCache[pdfURL], !pageData.isEmpty else {
            return nil
        }
        
        var annotationsData: [String: String] = [:]
        for (pageIndex, data) in pageData {
            annotationsData["page_\(pageIndex)"] = data.base64EncodedString()
        }
        
        // 3. Write to file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfName = pdfURL.deletingPathExtension().lastPathComponent
        let annotationURL = documentsPath.appendingPathComponent("\(pdfName)_annotations.json")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: annotationsData)
            try jsonData.write(to: annotationURL)
            print("✅ Annotations saved: \(annotationURL.lastPathComponent)")
            return annotationURL
        } catch {
            print("❌ Save error: \(error)")
            return nil
        }
    }
    
    /// Load PencilKit drawings from saved data into caching memory
    func loadAnnotationsToCache(pdfURL: URL) {
        if PDFAnnotationManager.annotationsCache[pdfURL] != nil { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfName = pdfURL.deletingPathExtension().lastPathComponent
        let annotationURL = documentsPath.appendingPathComponent("\(pdfName)_annotations.json")
        
        var pageDataMap: [Int: Data] = [:]
        
        if FileManager.default.fileExists(atPath: annotationURL.path),
           let jsonData = try? Data(contentsOf: annotationURL),
           let annotationsDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] {
            
            for (key, base64String) in annotationsDict {
                if let pageIndexStr = key.split(separator: "_").last,
                   let pageIndex = Int(pageIndexStr),
                   let drawingData = Data(base64Encoded: base64String) {
                    pageDataMap[pageIndex] = drawingData
                }
            }
            print("✅ Annotations loaded: \(pdfName)")
        }
        
        PDFAnnotationManager.annotationsCache[pdfURL] = pageDataMap
    }
    
    /// Get drawing for a specific page from cache
    func getDrawing(for pageIndex: Int, pdfURL: URL) -> PKDrawing? {
        guard let pageData = PDFAnnotationManager.annotationsCache[pdfURL]?[pageIndex] else { return nil }
        return try? PKDrawing(data: pageData)
    }
    
    /// Helper to update a single page in cache (used during live editing)
    func updateCache(for pageIndex: Int, canvasView: PKCanvasView, pdfURL: URL) {
        if PDFAnnotationManager.annotationsCache[pdfURL] == nil {
            PDFAnnotationManager.annotationsCache[pdfURL] = [:]
        }
        if let data = try? canvasView.drawing.dataRepresentation() {
            PDFAnnotationManager.annotationsCache[pdfURL]?[pageIndex] = data
        }
    }
    
    // MARK: - Option 2: Save Full PDF with Embedded Annotations
    
    /// Export PDF with PencilKit drawings embedded as PDF annotations
    //    func exportPDFWithAnnotations(
    //        pdfDocument: PDFDocument,
    //        canvasViews: [Int: PKCanvasView],
    //        originalURL: URL
    //    ) -> URL? {
    //        // Create a copy of the PDF
    //        guard let pdfCopy = PDFDocument(url: originalURL) else {
    //            print("❌ Could not create PDF copy")
    //            return nil
    //        }
    //
    //        // Convert PencilKit drawings to images and add as PDF annotations
    //        for (pageIndex, canvasView) in canvasViews {
    //            guard let page = pdfCopy.page(at: pageIndex) else { continue }
    //
    //            let drawing = canvasView.drawing
    //
    //            // Skip empty drawings
    //            if drawing.bounds.isEmpty { continue }
    //
    //            // Render drawing to image
    //            let renderer = UIGraphicsImageRenderer(bounds: canvasView.bounds)
    //            let image = renderer.image { context in
    //                drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale).draw(in: canvasView.bounds)
    //            }
    //
    //            // Create image annotation
    //            let pageBounds = page.bounds(for: .mediaBox)
    //            if let imageAnnotation = PDFAnnotation(bounds: pageBounds, forType: .stamp, withProperties: nil) {
    //                imageAnnotation.setImageAsStamp(image)
    //                page.addAnnotation(imageAnnotation)
    //            }
    //        }
    //
    //        // Save to new file
    //        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    //        let pdfName = originalURL.deletingPathExtension().lastPathComponent
    //        let outputURL = documentsPath.appendingPathComponent("\(pdfName)_annotated.pdf")
    //
    //        if pdfCopy.write(to: outputURL) {
    //            print("✅ Annotated PDF saved to: \(outputURL)")
    //            return outputURL
    //        } else {
    //            print("❌ Failed to save PDF")
    //            return nil
    //        }
    //    }
    
    // MARK: - Option 3: Hybrid - Export Flattened PDF (Best for Sharing)
    
    /// Creates a new PDF with drawings permanently merged (flattened)
    func exportFlattenedPDF(
        pdfDocument: PDFDocument,
        canvasViews: [Int: PKCanvasView],
        pdfView: PDFView,
        originalURL: URL
    ) -> URL? {
        let format = UIGraphicsPDFRendererFormat()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfName = originalURL.deletingPathExtension().lastPathComponent
        let outputURL = documentsPath.appendingPathComponent("\(pdfName)_flattened.pdf")
        
        let renderer = UIGraphicsPDFRenderer(bounds: pdfView.bounds, format: format)
        
        do {
            try renderer.writePDF(to: outputURL) { context in
                for pageIndex in 0..<pdfDocument.pageCount {
                    guard let page = pdfDocument.page(at: pageIndex) else { continue }
                    
                    let pageBounds = page.bounds(for: .mediaBox)
                    context.beginPage(withBounds: pageBounds, pageInfo: [:])
                    
                    // Draw PDF page
                    if let ctx = UIGraphicsGetCurrentContext() {
                        ctx.saveGState()
                        ctx.translateBy(x: 0, y: pageBounds.height)
                        ctx.scaleBy(x: 1.0, y: -1.0)
                        page.draw(with: .mediaBox, to: ctx)
                        ctx.restoreGState()
                        
                        // Draw PencilKit annotations on top
                        if let canvasView = canvasViews[pageIndex] {
                            let drawing = canvasView.drawing
                            let image = drawing.image(from: pageBounds, scale: UIScreen.main.scale)
                            image.draw(in: pageBounds)
                        }
                    }
                }
            }
            print("✅ Flattened PDF saved to: \(outputURL)")
            return outputURL
        } catch {
            print("❌ Error creating flattened PDF: \(error)")
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
            self.setValue(imageData, forAnnotationKey: .appearanceDictionary)
        }
    }
}
