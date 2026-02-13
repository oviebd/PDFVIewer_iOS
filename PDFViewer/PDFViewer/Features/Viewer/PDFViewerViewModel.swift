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
    @Published var annotationViewModel: AnnotationViewModel
    @Published var zoomScale: CGFloat = 1.0
    @Published var readingMode: ReadingMode = .normal
    @Published var showControls = true
    @Published var showBrightnessControls = false
    @Published var actions: PDFKitViewActions
    @Published var settings = PDFSettings()
    @Published var displayBrightness: CGFloat = 100
    @Published var pageProgressText: String = ""

    private var repository: PDFRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var backgroundCancellables = Set<AnyCancellable>()
    private let pageChangeSubject = PassthroughSubject<Int, Never>()


    init(pdfFile: PDFModelData, repository: PDFRepositoryProtocol) {
        let initialActions = PDFKitViewActions()
        let resolvedURL = pdfFile.resolveSecureURL()
        
        self.pdfData = pdfFile
        self.currentPDF = resolvedURL
        self.repository = repository
        self.actions = initialActions
        
        self.annotationViewModel = AnnotationViewModel(pdfData: pdfFile, currentPDF: resolvedURL, actions: initialActions, repository: repository)
        
        readingMode = ReadingMode(rawValue: UserDefaultsHelper.shared.savedReadingMode ?? "") ?? .normal
        displayBrightness = UserDefaultsHelper.shared.savedBrightness
        
        if let url = currentPDF {
            repository.getSingleData(pdfKey: pdfData.key)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    if case .failure(_) = completion {
                    }
                }, receiveValue: { [weak self] updatedModel in
                    self?.pdfData.annotationdata = updatedModel.annotationdata
                    self?.pdfData.lastOpenedPage = updatedModel.lastOpenedPage
                    self?.pdfData.lastOpenTime = updatedModel.lastOpenTime
                    
                    // Update last opened time NOW that we have synced
                    self?.pdfData.lastOpenTime = Date()
                    self?.saveToDB()
                    
                    self?.actions.loadAnnotations(from: updatedModel.annotationdata, for: url)
                    self?.goToPage()
                })
                .store(in: &cancellables)
        }

        pageChangeSubject
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] page in
                self?.saveLastOpenedPageNumberInDb()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
        debugPrint("U>> Deinit PdfViewerViewModel")
    }
    
    func unloadPdfData(){
        saveLastOpenedPageNumberInDb(isFinal: true)
        currentPDF?.stopAccessingSecurityScopedResource()
        cancellables.removeAll()
    }
    
    func onReadingModeChanged(readingMode: ReadingMode) {
        UserDefaultsHelper.shared.savedReadingMode = readingMode.rawValue
        self.readingMode = readingMode
    }

    func zoomIn() {
        zoomScale = min(zoomScale + 0.2, 5.0)
        actions.setZoomScale(scaleFactor: zoomScale)
    }

    func zoomOut() {
        zoomScale = max(zoomScale - 0.2, 0.5)
        actions.setZoomScale(scaleFactor: zoomScale)
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

    func saveLastOpenedPageNumberInDb(isFinal: Bool = false) {
        if let lastOpenedPageNumber = actions.getCurrentPageNumber() {
            pdfData.lastOpenedPage = lastOpenedPageNumber
            saveToDB(isFinal: isFinal)
        }
    }

    func saveToDB(isFinal: Bool = false) {
        let publisher = repository.update(updatedPdfData: pdfData)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(_) = completion {
                }
            }, receiveValue: { updatedModel in
            })
        
        if isFinal {
            publisher.store(in: &backgroundCancellables)
        } else {
            publisher.store(in: &cancellables)
        }
    }
}

extension PDFViewerViewModel {
   
    func startTrackingProgress() {
        
        actions.onPageChanged = { [weak self] _ in
            self?.preparePageProgressText()
            self?.saveLastOpenedPageNumberInDb()
        }
    }

    func goToPage() {
        actions.goPage(pageNumber: pdfData.lastOpenedPage)
    }
}
