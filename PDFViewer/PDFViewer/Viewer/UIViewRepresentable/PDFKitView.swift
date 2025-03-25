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
    @Binding var mode: AnnotationMode
    let pdfDrawer = PDFDrawer()

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: pdfURL)
        applySettings(to: pdfView)

        let pdfDrawingGestureRecognizer = DrawingGestureRecognizer()
        pdfView.addGestureRecognizer(pdfDrawingGestureRecognizer)
        pdfDrawingGestureRecognizer.drawingDelegate = pdfDrawer
        pdfDrawer.pdfView = pdfView

      
     

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
 
    }

    private func applySettings(to pdfView: PDFView) {
        pdfView.autoScales = settings.autoScales
        pdfView.displayMode = settings.displayMode
        pdfView.displayDirection = settings.displayDirection
    }

    class Coordinator: NSObject {
        var parent: PDFKitView
        var pdfView: PDFView?
        var mode: AnnotationMode = .none

        init(_ parent: PDFKitView) {
            self.parent = parent
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let pdfView = pdfView,
                  let page = pdfView.page(for: sender.location(in: pdfView), nearest: true) else {
                return
            }

            let location = sender.location(in: pdfView)
            let pagePoint = pdfView.convert(location, to: page)

            switch mode {
            case .highlight:
                let highlight = PDFAnnotation(bounds: CGRect(x: pagePoint.x - 50, y: pagePoint.y - 10, width: 100, height: 20),
                                              forType: .highlight,
                                              withProperties: nil)
                highlight.color = UIColor.yellow.withAlphaComponent(0.5)
                page.addAnnotation(highlight)

            case .erase:
                let annotations = page.annotations
                for annotation in annotations {
                    if annotation.bounds.contains(pagePoint) {
                        page.removeAnnotation(annotation)
                    }
                }

            case .none:
                break
            }
        }
    }
}
