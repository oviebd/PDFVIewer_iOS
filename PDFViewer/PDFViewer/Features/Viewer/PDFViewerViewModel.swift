//
//  PDFViewerViewModel.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 28/5/25.
//

import SwiftUI
import PDFKit

class PDFViewerViewModel: ObservableObject {
    @Published var pdfData: PDFModelData
    @Published var currentPDF: URL
    @Published var annotationSettingData: PDFAnnotationSetting = .noneData()
    @Published var zoomScale: CGFloat = 1.0
    @Published var readingMode: ReadingMode = .normal
    @Published var showPalette = false
    @Published var showControls = true
    @Published var showBrightnessControls = true
    @Published var actions = PDFKitViewActions()
    @Published var settings = PDFSettings()
    @Published var displayBrightness : CGFloat = 50.0

    init(pdfFile: PDFModelData) {
        self.pdfData = pdfFile
        self.currentPDF = URL(string: pdfFile.urlPath ?? "")!
    }

    func updateAnnotationSetting(_ setting: PDFAnnotationSetting, manager: DrawingToolManager) {
        annotationSettingData = setting
        manager.selectePdfdSetting = setting
        manager.updatePdfSettingData(newSetting: setting)
    }

    func zoomIn() {
        zoomScale = min(zoomScale + 0.2, 5.0)
        actions.setZoomScale(scaleFactor: zoomScale)
    }

    func zoomOut() {
        zoomScale = max(zoomScale - 0.2, 0.5)
        actions.setZoomScale(scaleFactor: zoomScale)
    }

    func savePDF() {
        _ = actions.saveAnnotedPdf(url: currentPDF)
    }
}
