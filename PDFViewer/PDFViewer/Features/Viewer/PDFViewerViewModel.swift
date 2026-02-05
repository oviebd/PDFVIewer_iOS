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
    @Published var currentPDF: URL?
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
        
        if let url = pdfFile.resolveSecureURL() {
            currentPDF = url
           // let document = PDFDocument(url: url)
            // Do something with the document
          /*  url.stopAccessingSecurityScopedResource()*/ // Don't forget this!
        }
        
      //  currentPDF = URL(string: pdfFile.urlPath ?? "")!
        self.repository = repository
        
        // REMOVED: This was clearing cancellables after 1s, which could cancel the DB fetch
        // DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        //    self.unloadPdfData()
        // }
        
    //    UserDefaultsHelper.shared.savedBrightness = 0
        readingMode = ReadingMode(rawValue: UserDefaultsHelper.shared.savedReadingMode ?? "") ?? .normal
        displayBrightness = UserDefaultsHelper.shared.savedBrightness
        
        if let url = currentPDF {
            repository.getSingleData(pdfKey: pdfData.key)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] updatedModel in
                    self?.pdfData.annotationdata = updatedModel.annotationdata
                    self?.actions.loadAnnotations(from: updatedModel.annotationdata, for: url)
                })
                .store(in: &cancellables)
        }
    }
    
    deinit {
        cancellables.removeAll()
        debugPrint("U>> Deinit PdfViewerViewModel")
    }
    
    func unloadPdfData(){
        currentPDF?.stopAccessingSecurityScopedResource()
        cancellables.removeAll()
    }
    
    func onReadingModeChanged(readingMode: ReadingMode) {
        UserDefaultsHelper.shared.savedReadingMode = readingMode.rawValue
        self.readingMode = readingMode
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
        guard let url = currentPDF else { return }
        let manager = PDFAnnotationManager()
        if let data = manager.getSerializedAnnotations(for: url) {
            pdfData.annotationdata = data
            saveToDB()
            print("✅ Annotations saved to DB")
        }
    }

    func getBrightnessOpacity() -> CGFloat {
        let brightnessPercentage: CGFloat = displayBrightness / 100
        let brightness = 1.0  - brightnessPercentage
        UserDefaultsHelper.shared.savedBrightness = displayBrightness
        return brightness
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
