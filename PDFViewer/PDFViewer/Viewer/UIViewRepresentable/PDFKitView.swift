//
//  PDFKitView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    @Binding var pdfURL: URL
    @ObservedObject var settings: PDFSettings
    @Binding var mode: DrawingTool

    @Binding var lineColor: UIColor
    @Binding var lineWidth: CGFloat
    @Binding var zoomScale: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: pdfURL)
        applySettings(to: pdfView)

        // Setup Drawer
        context.coordinator.drawer.pdfView = pdfView

        // Gesture recognizer for drawing
        let drawingGesture = DrawingGestureRecognizer()
        drawingGesture.drawingDelegate = context.coordinator.drawer
        pdfView.addGestureRecognizer(drawingGesture)

        // Save references
        context.coordinator.gestureRecognizer = drawingGesture
        context.coordinator.pdfView = pdfView

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Reload PDF when the URL changes
        let currentPage = pdfView.currentPage

        // If the PDF has changed, reload it
        if pdfView.document?.documentURL != pdfURL {
            pdfView.document = PDFDocument(url: pdfURL)
        }

        // Reapply settings
        applySettings(to: pdfView)

        // Restore page if available
        if let currentPage = currentPage {
            pdfView.go(to: currentPage)
        }
        
        // ✅ Toggle drawing gesture recognizer
           if let gesture = context.coordinator.gestureRecognizer {
               gesture.isEnabled = mode != .none
           }

        // ✅ Update the drawing tool and color here
//        context.coordinator.drawer.drawingTool = mode
//        context.coordinator.drawer.color = (mode == .highlighter)
//            ? UIColor.yellow.withAlphaComponent(mode.alpha)
//            : UIColor.red.withAlphaComponent(mode.alpha)
        
        context.coordinator.drawer.drawingTool = mode
               context.coordinator.drawer.color = lineColor.withAlphaComponent(mode.alpha)
               context.coordinator.drawer.lineWidth = lineWidth
        
        pdfView.scaleFactor = zoomScale
        
        
    }

    private func applySettings(to pdfView: PDFView) {
        pdfView.autoScales = settings.autoScales
        pdfView.displayMode = settings.displayMode
        pdfView.displayDirection = settings.displayDirection
    }

    // MARK: - Coordinator Keeps Objects Alive

    class Coordinator {
        let drawer = PDFDrawer()
        var gestureRecognizer: DrawingGestureRecognizer?
        var pdfView: PDFView?
    }
}

