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

    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false

    var onPageChanged: ((Int) -> Void)?
    var onAnnotationEditFinished: (() -> Void)?

    init() {
        annotationEditFinishedPublisher
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }

    func save(completion: ((Bool) -> Void)? = nil) {
        coordinator?.saveToDB(completion: completion)
    }

    func loadAnnotations(from data: Data?, for url: URL) {
        coordinator?.loadAnnotations(from: data, for: url)
    }
    
    func setZoomScale(scaleFactor: CGFloat) {
        coordinator?.setZoomSscale(scaleFactor: scaleFactor)
    }

    func goPage(pageNumber: Int) {
        coordinator?.goToPage(pageNumber)
    }

    func undo() {
        coordinator?.undo()
    }

    func redo() {
        coordinator?.redo()
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

class UndoableCanvasView: PKCanvasView {
    var injectedUndoManager: UndoManager?
    override var undoManager: UndoManager? {
        return injectedUndoManager ?? super.undoManager
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
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply initial settings
        pdfView.autoScales = settings.autoScales
        context.coordinator.lastAutoScales = settings.autoScales
        pdfView.displayMode = settings.displayMode
        pdfView.displayDirection = settings.displayDirection
        
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

        // Apply settings conditionally to avoid resetting zoom
        if context.coordinator.lastAutoScales != settings.autoScales {
            pdfView.autoScales = settings.autoScales
            context.coordinator.lastAutoScales = settings.autoScales
        }
        
        pdfView.displayMode = settings.displayMode
        pdfView.displayDirection = settings.displayDirection
        
        context.coordinator.updateTool(mode)
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
        private let annotationUndoManager = UndoManager()
        var lastAutoScales: Bool?


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
          
            canvasViews.values.forEach { $0.removeFromSuperview() }
            canvasViews.removeAll()
            pageOriginalSizes.removeAll() // We don't need this pre-calculated anymore
            
            // Refresh canvases from memory cache (in case they were loaded by ViewModel)
            refreshCanvasesFromCache()
            
            // Initial layout update
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
            guard let pdfView = pdfView, let containerView = containerView, let document = pdfView.document else { return }
            
            // 1. Identify currently visible pages
            let visiblePages = pdfView.visiblePages
            var visiblePageIndices = Set<Int>()
            
            for page in visiblePages {
                let index = document.index(for: page)
                if index != NSNotFound {
                    visiblePageIndices.insert(index)
                }
            }
            
            // 2. Remove canvases for pages that are no longer visible
            let currentIndices = Set(canvasViews.keys)
            let indicesToRemove = currentIndices.subtracting(visiblePageIndices)
            
            for index in indicesToRemove {
                if let canvasView = canvasViews[index] {
                    // Save latest changes to cache before removing view
                    if let url = pdfURL {
                        annotationManager.updateCache(for: index, canvasView: canvasView, pdfURL: url)
                    }
                    canvasView.removeFromSuperview()
                    canvasViews.removeValue(forKey: index)
                }
            }
            
            // 3. Add/Update canvases for visible pages
            for pageIndex in visiblePageIndices {
                guard let page = document.page(at: pageIndex) else { continue }
                let pageBounds = page.bounds(for: .mediaBox)
                let displayedPageFrame = pdfView.convert(pageBounds, from: page)
                
                // Create canvas if needed
                if canvasViews[pageIndex] == nil {
                    let canvasView = UndoableCanvasView()
                    canvasView.injectedUndoManager = annotationUndoManager
                    canvasView.backgroundColor = .clear
                    canvasView.isOpaque = false
                    canvasView.drawingPolicy = .anyInput
                    canvasView.delegate = self
                    
                    // Set correct tool (we need to access the current mode logic here)
                    // Since 'mode' is not directly accessible in Coordinator, we rely on updateTool being called or default
                    // We can re-apply the current tool state if we had access to it.
                    // Ideally, we store the current tool in the Coordinator.
                    if let tool = self.currentTool {
                        canvasView.tool = tool
                        canvasView.isUserInteractionEnabled = self.isDrawingEnabled
                    } else {
                        canvasView.isUserInteractionEnabled = false
                    }

                    canvasView.bounds = CGRect(origin: .zero, size: pageBounds.size)
                    
                    // Load drawing from cache
                    if let url = pdfURL, let drawing = annotationManager.getDrawing(for: pageIndex, pdfURL: url) {
                        canvasView.drawing = drawing
                    }
                    
                    canvasContainerView?.addSubview(canvasView)
                    canvasViews[pageIndex] = canvasView
                }
                
                // Update frame
                if let canvasView = canvasViews[pageIndex] {
                     let visibleBounds = containerView.bounds
                     // Optimization: Only show if actually intersecting visible area (though visiblePages check covers mostly)
                     if visibleBounds.intersects(displayedPageFrame) {
                         canvasView.isHidden = false
                         let scaleX = displayedPageFrame.width / pageBounds.width
                         let scaleY = displayedPageFrame.height / pageBounds.height
                         canvasView.center = CGPoint(x: displayedPageFrame.midX, y: displayedPageFrame.midY)
                         canvasView.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                     } else {
                         canvasView.isHidden = true
                     }
                }
            }
        }

        // We need to store current tool state to apply to new canvases
        var currentTool: PKTool?
        var isDrawingEnabled: Bool = false

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
            self.isDrawingEnabled = isDrawingEnabled
            
            switch setting.annotationTool {
            case .pen:
                tool = PKInkingTool(.pen, color: setting.color, width: setting.lineWidth)
            case .pencil:
                tool = PKInkingTool(.pencil, color: setting.color, width: setting.lineWidth)
            case .highlighter:
                tool = PKInkingTool(.marker, color: setting.color, width: setting.lineWidth)
            case .eraser:
                tool = PKEraserTool(.vector)
            default:
                tool = PKInkingTool(.pen, color: .clear, width: 0)
            }
            self.currentTool = tool
            
            pdfView?.isUserInteractionEnabled = !isDrawingEnabled
            canvasContainerView?.isUserInteractionEnabled = isDrawingEnabled
            
            for canvasView in canvasViews.values {
                canvasView.tool = tool
                canvasView.isUserInteractionEnabled = isDrawingEnabled
            }
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Find page index for this canvas
            if let index = canvasViews.first(where: { $0.value === canvasView })?.key, let url = pdfURL {
                 annotationManager.updateCache(for: index, canvasView: canvasView, pdfURL: url)
            }
            updateUndoRedoStates()
            actions?.notifyAnnotationEditingFinished()
        }

        func loadAnnotations(from data: Data?, for url: URL) {
            // Relaxed check: always attempt to load/update cache if data is provided,
            // even if the URL already exists in the cache.
            // If data is nil, it will clear annotations for the given URL.
            annotationManager.loadAnnotations(from: data, for: url)
            refreshCanvasesFromCache()
        }

        private func refreshCanvasesFromCache() {
            guard let url = pdfURL else { return }
            for (pageIndex, canvasView) in canvasViews {
                if let drawing = annotationManager.getDrawing(for: pageIndex, pdfURL: url) {
                    canvasView.drawing = drawing
                }
            }
        }

        func saveToDB(completion: ((Bool) -> Void)? = nil) {
            guard let url = pdfURL else {
                completion?(false)
                return
            }
            
            // Sync active views to cache first
            annotationManager.syncViewsToCache(canvasViews: canvasViews, pdfURL: url)
            
            // Trigger the ViewModel to save to DB
            // We can do this via the actions publisher or a callback
            actions?.onAnnotationEditFinished?()
            completion?(true)
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

        func updateUndoRedoStates() {
            actions?.canUndo = annotationUndoManager.canUndo
            actions?.canRedo = annotationUndoManager.canRedo
        }

        func getTotalPageNumber() -> Int? {
            return pdfView?.document?.pageCount
        }

        func undo() {
            annotationUndoManager.undo()
            updateUndoRedoStates()
        }

        func redo() {
            annotationUndoManager.redo()
            updateUndoRedoStates()
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
            
            // Final sync on close
            if let url = pdfURL {
                annotationManager.syncViewsToCache(canvasViews: canvasViews, pdfURL: url)
                actions?.onAnnotationEditFinished?()
            }
        }
    }
}
