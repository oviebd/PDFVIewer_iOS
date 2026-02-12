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
    @Published var lastDrawingColor: UIColor = .red
    @Published var zoomScale: CGFloat = 1.0
    @Published var readingMode: ReadingMode = .normal
    @Published var showPalette = false
    @Published var showControls = true
    @Published var showBrightnessControls = false
    @Published var actions = PDFKitViewActions()
    @Published var settings = PDFSettings()
    @Published var displayBrightness: CGFloat = 100
    @Published var pageProgressText: String = ""
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    @Published var showSaveSuccess: Bool = false
    @Published var shareURL: URL? = nil
    @Published var successFileName: String = ""
    @Published var successFileLocation: String = ""
    @Published var isSavingPDF: Bool = false
    @Published var showShareSheet: Bool = false

    private var repository: PDFRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var backgroundCancellables = Set<AnyCancellable>()
    private let pageChangeSubject = PassthroughSubject<Int, Never>()


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

    func selectTool(_ setting: PDFAnnotationSetting, manager: DrawingToolManager) {
        withAnimation {
            let newSetting = (annotationSettingData.annotationTool == setting.annotationTool) ? .noneData() : setting
            annotationSettingData = newSetting
            if newSetting.annotationTool != .none && newSetting.annotationTool != .eraser {
                lastDrawingColor = newSetting.color
            }
            manager.selectePdfdSetting = newSetting
            manager.updatePdfSettingData(newSetting: newSetting)
        }
    }

    func updateAnnotationData(_ setting: PDFAnnotationSetting, manager: DrawingToolManager) {
        withAnimation {
            annotationSettingData = setting
            if setting.annotationTool != .none && setting.annotationTool != .eraser {
                lastDrawingColor = setting.color
            }
            manager.selectePdfdSetting = setting
            manager.updatePdfSettingData(newSetting: setting)
        }
    }

    func zoomIn() {
        zoomScale = min(zoomScale + 0.2, 5.0)
        actions.setZoomScale(scaleFactor: zoomScale)
    }

    func zoomOut() {
        zoomScale = max(zoomScale - 0.2, 0.5)
        actions.setZoomScale(scaleFactor: zoomScale)
    }

    func undo() {
        actions.undo()
    }

    func redo() {
        actions.redo()
    }

    func autoSaveAnnotations() {
        guard let url = currentPDF else { return }
        let manager = PDFAnnotationManager()
        if let data = manager.getSerializedAnnotations(for: url) {
            pdfData.annotationdata = data
            saveToDB()
            print("✅ Annotations auto-saved to DB")
        }
    }

    func savePDFWithAnnotation() {
        guard let url = currentPDF else { return }
        let manager = PDFAnnotationManager()
        isSavingPDF = true
        
        // 1. Save to DB first
        if let data = manager.getSerializedAnnotations(for: url) {
            pdfData.annotationdata = data
            saveToDB()
            print("✅ Annotations saved to DB")
        }
        
        // 2. Save annotated file copy
        actions.saveAnnotatedCopy { [weak self] savedURL in
            DispatchQueue.main.async {
                self?.isSavingPDF = false
                if let savedURL = savedURL {
                    print("✅ PDF with annotations saved to: \(savedURL.path)")
                    self?.shareURL = savedURL
                    self?.successFileName = savedURL.lastPathComponent
                    self?.successFileLocation = savedURL.deletingLastPathComponent().path
                    self?.showSaveSuccess = true
                    // Note: showShareSheet is NOT set here, as per user request
                } else {
                    print("❌ Failed to save annotated PDF")
                }
            }
        }
    }

    func openSavedLocation() {
        guard let url = shareURL else { return }
        let folderURL = url.deletingLastPathComponent()
        
        print("📂 Attempting to open folder: \(folderURL.path)")
        
        // Start accessing security scope if it's a security-scoped URL
        let isScoped = folderURL.startAccessingSecurityScopedResource()
        
        UIApplication.shared.open(folderURL, options: [:]) { [weak self] success in
            if isScoped {
                folderURL.stopAccessingSecurityScopedResource()
            }
            
            if !success {
                print("⚠️ Direct folder open failed, trying Files app fallback.")
                self?.openFilesAppFallback()
            } else {
                print("✅ Successfully opened folder location.")
            }
        }
    }

    private func openFilesAppFallback() {
        // "shareddocuments://" opens the Files app. 
        // Note: Specific path deep-linking is limited in iOS.
        if let filesAppURL = URL(string: "shareddocuments://") {
            UIApplication.shared.open(filesAppURL, options: [:], completionHandler: nil)
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
        
        actions.onAnnotationEditFinished = { [weak self] in
             self?.autoSaveAnnotations()
        }

        actions.$canUndo
            .receive(on: RunLoop.main)
            .assign(to: \.canUndo, on: self)
            .store(in: &cancellables)

        actions.$canRedo
            .receive(on: RunLoop.main)
            .assign(to: \.canRedo, on: self)
            .store(in: &cancellables)
    }

    func goToPage() {
        actions.goPage(pageNumber: pdfData.lastOpenedPage)
    }
}
