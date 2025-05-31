//
//  PDFKitView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import PDFKit
import SwiftUI

class PDFKitViewActions: ObservableObject {
    fileprivate var coordinator: PDFKitView.Coordinator?


    func saveAnnotatedPDFInBackground(to url: URL, completion: @escaping (Bool) -> Void) {
        coordinator?.saveAnnotatedPDF(to: url, completion: completion)
    }

    func setZoomScale(scaleFactor: CGFloat) {
        coordinator?.setZoomSscale(scaleFactor: scaleFactor)
    }

    func goPage(pageNumber: Int) {
        coordinator?.goToPage(pageNumber)
    }

    func getCurrentPageNumber() -> Int? {
        return coordinator?.getCurrentPageNumber()
    }

    func getTotalPageNumber() -> Int? {
        return coordinator?.getTotalPageNumber()
    }
}

struct PDFKitView: UIViewRepresentable {
    @Binding var pdfURL: URL
    @ObservedObject var settings: PDFSettings
    @Binding var mode: PDFAnnotationSetting

    @ObservedObject var actions: PDFKitViewActions

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: pdfURL)
        applySettings(to: pdfView)

        print("P>> Make Ui View ")
        // Setup Drawer
        context.coordinator.drawer.pdfView = pdfView

        // Gesture recognizer for drawing
        let drawingGesture = DrawingGestureRecognizer()
        drawingGesture.drawingDelegate = context.coordinator.drawer
        pdfView.addGestureRecognizer(drawingGesture)

        // Save references
        context.coordinator.gestureRecognizer = drawingGesture
        context.coordinator.pdfView = pdfView

        // 👇 Connect the coordinator to actions
        actions.coordinator = context.coordinator

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Reload PDF when the URL changes
        // let currentPage = pdfView.currentPage

        print("P>> Update Ui View ")
        // If the PDF has changed, reload it
        if pdfView.document?.documentURL != pdfURL {
            pdfView.document = PDFDocument(url: pdfURL)
        }

        // Reapply settings
        applySettings(to: pdfView)

        if let gesture = context.coordinator.gestureRecognizer {
            gesture.isEnabled = mode.annotationTool != .none
        }

        // ✅ Update the drawing tool and color here
        context.coordinator.drawer.annotationSetting = mode
    }

    private func applySettings(to pdfView: PDFView) {
        pdfView.autoScales = settings.autoScales
        pdfView.displayMode = settings.displayMode
        pdfView.displayDirection = settings.displayDirection
    }

    // MARK: - Coordinator Keeps Objects Alive

    class Coordinator: NSObject, PDFViewDelegate {

        let drawer = PDFDrawer()
        var gestureRecognizer: DrawingGestureRecognizer?
        var pdfView: PDFView?


        func saveAnnotatedPDF(to url: URL, completion: @escaping (Bool) -> Void) {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let document = self.pdfView?.document else {
                    print("No PDF document found in PDFView")
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }

                let success = document.write(to: url)

                DispatchQueue.main.async {
                    if success {
                        print("PDF saved successfully to \(url)")
                    } else {
                        print("Failed to save PDF")
                    }
                    completion(success)
                }
            }
        }

        func setZoomSscale(scaleFactor: CGFloat) {
            pdfView?.scaleFactor = scaleFactor
        }

        func goToPage(_ number: Int) {
            guard let pdfView = pdfView,
                  let document = pdfView.document,
                  number > 0, number <= document.pageCount,
                  let page = document.page(at: number - 1) else { return }

            pdfView.go(to: page)
        }

        func getTotalPageNumber() -> Int? {
            guard let pdfView = pdfView,
                  let document = pdfView.document else { return nil }
            return document.pageCount
        }

        func getCurrentPageNumber() -> Int? {
            guard let pdfView = pdfView, let currentPage = pdfView.currentPage,
                  let index = pdfView.document?.index(for: currentPage) else {
                return nil
            }
            return index + 1
        }
    }
}
