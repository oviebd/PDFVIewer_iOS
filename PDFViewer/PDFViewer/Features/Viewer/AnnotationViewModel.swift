//
//  AnnotationViewModel.swift
//  PDFViewer
//
//  Created by Antigravity on 12/2/26.
//

import Combine
import PDFKit
import SwiftUI

class AnnotationViewModel: ObservableObject {
    @Published var annotationSettingData: PDFAnnotationSetting = .noneData()
    @Published var lastDrawingColor: UIColor = .red
    @Published var showPalette: Bool = false
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    @Published var isExportingPDF: Bool = false
    @Published var showSaveSuccess: Bool = false
    @Published var shareURL: URL? = nil
    @Published var successFileName: String = ""
    @Published var successFileLocation: String = ""
    @Published var showShareSheet: Bool = false
    
    // MARK: - Subscription Check
    private let subscriptionManager = SubscriptionManager.shared
    var onPremiumRestricted: ((String) -> Void)?
    
    private let actions: PDFKitViewActions
    private let repository: PDFRepositoryProtocol
    private var pdfData: PDFModelData
    private var currentPDF: URL?
    private var cancellables = Set<AnyCancellable>()
    
    init(pdfData: PDFModelData, currentPDF: URL?, actions: PDFKitViewActions, repository: PDFRepositoryProtocol) {
        self.pdfData = pdfData
        self.currentPDF = currentPDF
        self.actions = actions
        self.repository = repository
        
        setupBindings()
    }
    
    private func setupBindings() {
        actions.$canUndo
            .receive(on: RunLoop.main)
            .assign(to: \.canUndo, on: self)
            .store(in: &cancellables)

        actions.$canRedo
            .receive(on: RunLoop.main)
            .assign(to: \.canRedo, on: self)
            .store(in: &cancellables)
            
        actions.onAnnotationEditFinished = { [weak self] in
             self?.autoSaveAnnotations()
        }
    }
    
    func updatePdfData(_ data: PDFModelData) {
        self.pdfData = data
    }
    
    func updateCurrentPDF(_ url: URL?) {
        self.currentPDF = url
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

    func undo() {
        if subscriptionManager.isAnnotationHistoryAllowed {
            actions.undo()
        } else {
            onPremiumRestricted?("Undo/Redo for annotations is a Premium feature. Upgrade to enable it.")
        }
    }

    func redo() {
        if subscriptionManager.isAnnotationHistoryAllowed {
            actions.redo()
        } else {
            onPremiumRestricted?("Undo/Redo for annotations is a Premium feature. Upgrade to enable it.")
        }
    }

    func autoSaveAnnotations() {
        guard let url = currentPDF else { return }
        let manager = PDFAnnotationManager()
        if let data = manager.getSerializedAnnotations(for: url) {
            pdfData.annotationdata = data
            saveToDB()
            debugPrint("✅ Annotations auto-saved to DB")
        }
    }

    func exportPdf() {
        guard subscriptionManager.isExportAllowed else {
            onPremiumRestricted?("Export is a Premium feature. Upgrade to enable PDF exporting.")
            return
        }
        
        guard let url = currentPDF else { return }
        let manager = PDFAnnotationManager()
        isExportingPDF = true
        
        // 1. Save to DB first
        if let data = manager.getSerializedAnnotations(for: url) {
            pdfData.annotationdata = data
            saveToDB()
            debugPrint("✅ Annotations saved to DB")
        }
        
        // 2. Save annotated file copy
        actions.exportAnnotatedPdf { [weak self] savedURL in
            DispatchQueue.main.async {
                self?.isExportingPDF = false
                if let savedURL = savedURL {
                    debugPrint("✅ PDF with annotations saved to: \(savedURL.path)")
                    self?.shareURL = savedURL
                    self?.successFileName = savedURL.lastPathComponent
                    self?.successFileLocation = savedURL.deletingLastPathComponent().path
                    self?.showSaveSuccess = true
                } else {
                    debugPrint("❌ Failed to save annotated PDF")
                }
            }
        }
    }

    func openSavedLocation() {
        guard let url = shareURL else { return }
        let folderURL = url.deletingLastPathComponent()
        
        let isScoped = folderURL.startAccessingSecurityScopedResource()
        
        UIApplication.shared.open(folderURL, options: [:]) { success in
            if isScoped {
                folderURL.stopAccessingSecurityScopedResource()
            }
            
            if !success {
                if let filesAppURL = URL(string: "shareddocuments://") {
                    UIApplication.shared.open(filesAppURL, options: [:], completionHandler: nil)
                }
            }
        }
    }

    private func saveToDB() {
        repository.update(updatedPdfData: pdfData)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
