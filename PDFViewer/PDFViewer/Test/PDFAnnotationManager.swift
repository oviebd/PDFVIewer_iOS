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
    
    /// Save PencilKit drawings to static cache
    func saveToCache(canvasViews: [Int: PKCanvasView], pdfURL: URL) {
        var pageData: [Int: Data] = [:]
        for (pageIndex, canvasView) in canvasViews {
            if let data = try? canvasView.drawing.dataRepresentation() {
                pageData[pageIndex] = data
            }
        }
        PDFAnnotationManager.annotationsCache[pdfURL] = pageData
    }
    
    /// Load PencilKit drawings from static cache
    func loadFromCache(pdfURL: URL, into canvasViews: [Int: PKCanvasView]) {
        guard let pageData = PDFAnnotationManager.annotationsCache[pdfURL] else { return }
        for (pageIndex, data) in pageData {
            if let canvasView = canvasViews[pageIndex],
               let drawing = try? PKDrawing(data: data) {
                canvasView.drawing = drawing
            }
        }
    }

    // MARK: - Option 1: Save Annotations Separately (RECOMMENDED)
    
    /// Save PencilKit drawings as separate data
    func saveAnnotationsData(canvasViews: [Int: PKCanvasView], pdfURL: URL) -> URL? {
        var annotationsData: [String: Data] = [:]
        
        // Save each page's drawing
        for (pageIndex, canvasView) in canvasViews {
            let drawing = canvasView.drawing
            if let drawingData = try? drawing.dataRepresentation() {
                annotationsData["page_\(pageIndex)"] = drawingData
            }
        }
        
        // Save to file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfName = pdfURL.deletingPathExtension().lastPathComponent
        let annotationURL = documentsPath.appendingPathComponent("\(pdfName)_annotations.json")
        
        do {
            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject:
                annotationsData.mapValues { $0.base64EncodedString() }
            )
            try jsonData.write(to: annotationURL)
            print("✅ Annotations saved to: \(annotationURL)")
            return annotationURL
        } catch {
            print("❌ Error saving annotations: \(error)")
            return nil
        }
    }
    
    /// Load PencilKit drawings from saved data
    func loadAnnotationsData(pdfURL: URL, into canvasViews: [Int: PKCanvasView]) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfName = pdfURL.deletingPathExtension().lastPathComponent
        let annotationURL = documentsPath.appendingPathComponent("\(pdfName)_annotations.json")
        
        guard FileManager.default.fileExists(atPath: annotationURL.path) else {
            print("ℹ️ No saved annotations found")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: annotationURL)
            if let annotationsDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: String] {
                for (key, base64String) in annotationsDict {
                    // Extract page index
                    if let pageIndexStr = key.split(separator: "_").last,
                       let pageIndex = Int(pageIndexStr),
                       let drawingData = Data(base64Encoded: base64String),
                       let drawing = try? PKDrawing(data: drawingData),
                       let canvasView = canvasViews[pageIndex] {
                        canvasView.drawing = drawing
                    }
                }
                print("✅ Annotations loaded successfully")
            }
        } catch {
            print("❌ Error loading annotations: \(error)")
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
