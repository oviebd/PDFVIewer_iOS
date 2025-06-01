//
//  PDFViewerViewModel.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 28/5/25.
//

import Combine
import PDFKit
import SwiftUI

class PDFViewerViewModel: ObservableObject {
    @Published var pdfData: PDFModelData
    @Published var currentPDF: URL
    @Published var annotationSettingData: PDFAnnotationSetting = .noneData()
    @Published var zoomScale: CGFloat = 1.0
    @Published var readingMode: ReadingMode = .normal
    @Published var showPalette = false
    @Published var showControls = true
    @Published var showBrightnessControls = false
    @Published var actions = PDFKitViewActions()
    @Published var settings = PDFSettings()
    @Published var displayBrightness: CGFloat = 100
    @Published var pageProgressText: String = ""

    private var repository: PDFRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()


    init(pdfFile: PDFModelData, repository: PDFRepositoryProtocol) {
        pdfData = pdfFile
        currentPDF = URL(string: pdfFile.urlPath ?? "")!
        self.repository = repository
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

    func savePDFWithAnnotation() {
        actions.saveAnnotatedPDFInBackground(to: currentPDF) { success in
            if success {
                // Show success UI or alert
            } else {
                // Show failure UI or retry option
            }
        }
        //  _ = actions.saveAnnotedPdf(url: currentPDF)
    }

    func getBrightnessOpacity() -> CGFloat {
        let bifgtnessPercentage: CGFloat = displayBrightness / 100
        return 1.0 - bifgtnessPercentage
    }

    func preparePageProgressText() {
        let currentPage = actions.getCurrentPageNumber() ?? 0
        let totalPageCount = actions.getTotalPageNumber() ?? 0
        pageProgressText = "\(currentPage)/\(totalPageCount)"
    }
}

// Db
extension PDFViewerViewModel {
    func updateLastOpenedtime() {
        pdfData.lastOpenTime = Date()
        saveToDB()
    }

    func saveLastOpenedPageNumberInDb() {
        if let lastOpenedPageNumber = actions.getCurrentPageNumber() {
            pdfData.lastOpenedPage = lastOpenedPageNumber
            saveToDB()
        }
    }

    func saveToDB() {
        repository.update(updatedPdfData: pdfData)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                //  self?.UpdatePdfList(updatedModel: updatedModel)
            })
            .store(in: &cancellables)
    }
}

extension PDFViewerViewModel {
   
    func startTrackingProgress() {
        
        actions.onPageChanged = { [weak self] _ in
            self?.preparePageProgressText()
            self?.saveLastOpenedPageNumberInDb()
        }
        
        actions.onAnnotationEditFinished = { [weak self] in
            self?.savePDFWithAnnotation()
        }
    }

    func goToPage() {
        actions.goPage(pageNumber: pdfData.lastOpenedPage)
    }
}
