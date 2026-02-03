//
//  PDFKitView.swift
//  PDFViewer
//
//  Created by Habibur Rahman on 25/3/25.
//

import Combine
import PDFKit
import PencilKit
import SwiftUI

class PDFKitViewActions: ObservableObject {
    fileprivate weak var coordinator: PDFKitView.Coordinator?
    fileprivate let annotationEditFinishedPublisher = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    var onPageChanged: ((Int) -> Void)?
    var onAnnotationEditFinished: (() -> Void)?

    init() {
        annotationEditFinishedPublisher
            .debounce(for: .milliseconds(2000), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.onAnnotationEditFinished?()
            }
            .store(in: &cancellables)
    }

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

    func notifyPageChange(_ page: Int) {
        onPageChanged?(page)
    }

    func notifyAnnotationEditingFinished() {
        annotationEditFinishedPublisher.send()
    }
    
    deinit{
        cancellables.removeAll()
    }
}

struct PDFKitView: UIViewRepresentable {
    var pdfURL: URL
    @ObservedObject var settings: PDFSettings
    @Binding var mode: PDFAnnotationSetting

    @ObservedObject var actions: PDFKitViewActions

    func makeCoordinator() -> Coordinator {
        Coordinator(actions: actions)
    }
    

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.clipsToBounds = true
        
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: pdfURL)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        applySettings(to: pdfView)
        containerView.addSubview(pdfView)

        let canvasContainerView = UIView()
        canvasContainerView.backgroundColor = .clear
        canvasContainerView.isUserInteractionEnabled = false
        canvasContainerView.clipsToBounds = true
        canvasContainerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(canvasContainerView)

        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: containerView.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            canvasContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            canvasContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            canvasContainerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            canvasContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        context.coordinator.pdfView = pdfView
        context.coordinator.canvasContainerView = canvasContainerView
        context.coordinator.containerView = containerView
        context.coordinator.pdfURL = pdfURL
        context.coordinator.setup()

        actions.coordinator = context.coordinator
        context.coordinator.startPollingPageChanges()

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let pdfView = context.coordinator.pdfView else { return }
        context.coordinator.pdfURL = pdfURL
        
        if pdfView.document?.documentURL != pdfURL {
            pdfView.document = PDFDocument(url: pdfURL)
            context.coordinator.refreshDocument()
        }

        applySettings(to: pdfView)
        context.coordinator.updateTool(mode)
    }

    private func applySettings(to pdfView: PDFView) {
        pdfView.autoScales = settings.autoScales
        pdfView.displayMode = settings.displayMode
        pdfView.displayDirection = settings.displayDirection
    }

    // MARK: - Coordinator Keeps Objects Alive

    class Coordinator: NSObject, PKCanvasViewDelegate, UIGestureRecognizerDelegate {
        var pdfView: PDFView?
        var canvasContainerView: UIView?
        var containerView: UIView?
        weak var actions: PDFKitViewActions?
        var pdfURL: URL?
        private let annotationManager = PDFAnnotationManager()
        
        var canvasViews: [Int: PKCanvasView] = [:]
        var pageOriginalSizes: [Int: CGSize] = [:]
        var displayLink: CADisplayLink?
        private var timerPublisher: AnyCancellable?
        private let pdfSaveQueue = DispatchQueue(label: "com.yourapp.pdfSaveQueue")

        init(actions: PDFKitViewActions) {
            self.actions = actions
            super.init()
        }

        func setup() {
            guard let pdfView = pdfView else { return }
            
            refreshDocument()
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(pdfViewChanged),
                name: .PDFViewPageChanged,
                object: pdfView
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(pdfViewChanged),
                name: .PDFViewScaleChanged,
                object: pdfView
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(pdfViewChanged),
                name: .PDFViewVisiblePagesChanged,
                object: pdfView
            )
            
            startDisplayLink()
        }
        
        func refreshDocument() {
            guard let document = pdfView?.document else { return }
            
            // Clear old canvases
            canvasViews.values.forEach { $0.removeFromSuperview() }
            canvasViews.removeAll()
            pageOriginalSizes.removeAll()
            
            // Store original sizes and create canvases
            for pageIndex in 0..<document.pageCount {
                if let page = document.page(at: pageIndex) {
                    let originalSize = page.bounds(for: .mediaBox).size
                    pageOriginalSizes[pageIndex] = originalSize
                    
                    let canvasView = PKCanvasView()
                    canvasView.backgroundColor = .clear
                    canvasView.isOpaque = false
                    canvasView.drawingPolicy = .anyInput
                    canvasView.delegate = self
                    canvasView.isUserInteractionEnabled = false
                    canvasView.bounds = CGRect(origin: .zero, size: originalSize)
                    
                    canvasContainerView?.addSubview(canvasView)
                    canvasViews[pageIndex] = canvasView
                }
            }
            
            // Load from disk (sidecar file)
            if let url = pdfURL {
                annotationManager.loadAnnotationsData(pdfURL: url, into: canvasViews)
            }
            
            updateCanvasFrames()
        }

        func startDisplayLink() {
            displayLink = CADisplayLink(target: self, selector: #selector(updateCanvasFrames))
            displayLink?.add(to: .main, forMode: .common)
        }
        
        func stopDisplayLink() {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        @objc func pdfViewChanged() {
            updateCanvasFrames()
            if let page = getCurrentPageNumber() {
                actions?.notifyPageChange(page)
            }
        }
        
        @objc func updateCanvasFrames() {
            guard let pdfView = pdfView, let containerView = containerView else { return }
            let visibleBounds = containerView.bounds
            
            for (pageIndex, canvasView) in canvasViews {
                guard let page = pdfView.document?.page(at: pageIndex),
                      let originalSize = pageOriginalSizes[pageIndex] else { continue }
                
                let displayedPageFrame = pdfView.convert(page.bounds(for: .mediaBox), from: page)
                let isPageVisible = visibleBounds.intersects(displayedPageFrame)
                
                if !isPageVisible {
                    canvasView.isHidden = true
                } else {
                    canvasView.isHidden = false
                    let scaleX = displayedPageFrame.width / originalSize.width
                    let scaleY = displayedPageFrame.height / originalSize.height
                    
                    canvasView.center = CGPoint(x: displayedPageFrame.midX, y: displayedPageFrame.midY)
                    canvasView.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                }
            }
        }

        func startPollingPageChanges() {
            timerPublisher?.cancel()
            timerPublisher = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .map { [weak self] _ -> Int? in
                    self?.getCurrentPageNumber()
                }
                .compactMap { $0 }
                .removeDuplicates()
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
                .sink { [weak self] currentIndex in
                    self?.actions?.notifyPageChange(currentIndex)
                }
        }

        func updateTool(_ setting: PDFAnnotationSetting) {
            let tool: PKTool
            let isDrawingEnabled = setting.annotationTool != .none
            
            switch setting.annotationTool {
            case .pen:
                tool = PKInkingTool(.pen, color: setting.color, width: setting.lineWidth)
            case .highlighter:
                tool = PKInkingTool(.marker, color: setting.color, width: setting.lineWidth)
            case .eraser:
                tool = PKEraserTool(.vector)
            default:
                tool = PKInkingTool(.pen, color: .clear, width: 0)
            }
            
            pdfView?.isUserInteractionEnabled = !isDrawingEnabled
            canvasContainerView?.isUserInteractionEnabled = isDrawingEnabled
            
            for canvasView in canvasViews.values {
                canvasView.tool = tool
                canvasView.isUserInteractionEnabled = isDrawingEnabled
            }
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            if let url = pdfURL {
                // Also save to cache for instant recovery
                annotationManager.saveToCache(canvasViews: canvasViews, pdfURL: url)
            }
            actions?.notifyAnnotationEditingFinished()
        }

        func saveAnnotatedPDF(to url: URL, completion: @escaping (Bool) -> Void) {
            // We now use sidecar saving instead of rewriting the PDF.
            // This avoids locking/password issues with security-sensitive PDFs.
            pdfSaveQueue.async {
                let savedURL = self.annotationManager.saveAnnotationsData(canvasViews: self.canvasViews, pdfURL: url)
                DispatchQueue.main.async {
                    completion(savedURL != nil)
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
            return pdfView?.document?.pageCount
        }

        func getCurrentPageNumber() -> Int? {
            guard let pdfView = pdfView, let currentPage = pdfView.currentPage,
                  let index = pdfView.document?.index(for: currentPage) else {
                return nil
            }
            return index + 1
        }

        deinit {
            stopDisplayLink()
            timerPublisher?.cancel()
            NotificationCenter.default.removeObserver(self)
        }
    }
}
