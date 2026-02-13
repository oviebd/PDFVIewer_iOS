import SwiftUI
import PDFKit
import PencilKit

// MARK: - Main PDF Annotation View
//struct PDFAnnotationView: View {
//    let pdfDocument: PDFDocument
//    @State private var selectedTool: AnnotationTool_PencilKit = .hand
//    @State private var currentPage: Int = 0
//    @State private var zoomScale: CGFloat = 1.0
//    
//    var body: some View {
//        ZStack(alignment: .bottomTrailing) {
//            VStack(spacing: 0) {
//                // Toolbar
//                HStack {
//                    Button(action: { selectedTool = .hand }) {
//                        Image(systemName: "hand.raised.fill")
//                            .padding(8)
//                            .background(selectedTool == .hand ? Color.green.opacity(0.3) : Color.clear)
//                            .cornerRadius(8)
//                    }
//                    
//                    Divider()
//                        .frame(height: 30)
//                    
//                    ForEach(AnnotationTool_PencilKit.allCases, id: \.self) { tool in
//                        Button(action: {
//                            selectedTool = tool
//                        }) {
//                            Image(systemName: tool.icon)
//                                .padding(8)
//                                .background(selectedTool == tool ? Color.blue.opacity(0.2) : Color.clear)
//                                .cornerRadius(8)
//                        }
//                    }
//                    
//                    Spacer()
//                    
//                    // Page Navigation
//                    HStack(spacing: 8) {
//                        Button(action: {
//                            if currentPage > 0 {
//                                currentPage -= 1
//                            }
//                        }) {
//                            Image(systemName: "chevron.left")
//                                .padding(8)
//                                .background(Color.gray.opacity(0.2))
//                                .cornerRadius(8)
//                        }
//                        .disabled(currentPage == 0)
//                        
//                        Text("\(currentPage + 1) / \(pdfDocument.pageCount)")
//                            .font(.caption)
//                            .padding(.horizontal, 8)
//                        
//                        Button(action: {
//                            if currentPage < pdfDocument.pageCount - 1 {
//                                currentPage += 1
//                            }
//                        }) {
//                            Image(systemName: "chevron.right")
//                                .padding(8)
//                                .background(Color.gray.opacity(0.2))
//                                .cornerRadius(8)
//                        }
//                        .disabled(currentPage == pdfDocument.pageCount - 1)
//                    }
//                }
//                .padding()
//                
//                // PDF with PencilKit overlay
//                PDFKitAnnotationView(
//                    document: pdfDocument,
//                    selectedTool: $selectedTool,
//                    currentPage: $currentPage,
//                    zoomScale: $zoomScale
//                )
//            }
//            
//            // Zoom Controls
//            VStack(spacing: 12) {
//                Button(action: {
//                    zoomScale = min(zoomScale + 0.25, 5.0)
//                }) {
//                    Image(systemName: "plus.magnifyingglass")
//                        .font(.system(size: 18, weight: .semibold))
//                        .foregroundColor(.white)
//                        .frame(width: 44, height: 44)
//                        .background(Color.blue)
//                        .clipShape(Circle())
//                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
//                }
//                .disabled(zoomScale >= 5.0)
//                .opacity(zoomScale >= 5.0 ? 0.5 : 1.0)
//                
//                Text("\(Int(zoomScale * 100))%")
//                    .font(.system(size: 11, weight: .medium))
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 10)
//                    .padding(.vertical, 5)
//                    .background(Color.black.opacity(0.75))
//                    .cornerRadius(12)
//                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
//                
//                Button(action: {
//                    zoomScale = max(zoomScale - 0.25, 0.5)
//                }) {
//                    Image(systemName: "minus.magnifyingglass")
//                        .font(.system(size: 18, weight: .semibold))
//                        .foregroundColor(.white)
//                        .frame(width: 44, height: 44)
//                        .background(Color.blue)
//                        .clipShape(Circle())
//                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
//                }
//                .disabled(zoomScale <= 0.5)
//                .opacity(zoomScale <= 0.5 ? 0.5 : 1.0)
//                
//                Button(action: {
//                    zoomScale = 1.0
//                }) {
//                    Image(systemName: "arrow.counterclockwise")
//                        .font(.system(size: 14, weight: .semibold))
//                        .foregroundColor(.white)
//                        .frame(width: 36, height: 36)
//                        .background(Color.gray.opacity(0.8))
//                        .clipShape(Circle())
//                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
//                }
//            }
//            .padding(.trailing, 20)
//            .padding(.bottom, 30)
//        }
//    }
//}
//
//// MARK: - Annotation Tools
//enum AnnotationTool_PencilKit: CaseIterable {
//    case pencil, pen, eraser, text, highlight, shape, comment
//    case hand
//    
//    var icon: String {
//        switch self {
//        case .hand: return "hand.raised"
//        case .pencil: return "pencil"
//        case .pen: return "pencil.tip"
//        case .eraser: return "eraser"
//        case .text: return "textformat"
//        case .highlight: return "highlighter"
//        case .shape: return "rectangle"
//        case .comment: return "bubble.left"
//        }
//    }
//}
//
//// MARK: - PDFKit + PencilKit Combined View
//struct PDFKitAnnotationView: UIViewRepresentable {
//    let document: PDFDocument
//    @Binding var selectedTool: AnnotationTool_PencilKit
//    @Binding var currentPage: Int
//    @Binding var zoomScale: CGFloat
//    
//    func makeUIView(context: Context) -> UIView {
//        let containerView = UIView()
//        containerView.clipsToBounds = true
//        
//        // PDFView setup
//        let pdfView = PDFView()
//        pdfView.document = document
//        pdfView.autoScales = true
//        pdfView.displayMode = .singlePageContinuous
//        pdfView.displayDirection = .vertical
//        pdfView.usePageViewController(false)
//        pdfView.translatesAutoresizingMaskIntoConstraints = false
//        pdfView.isUserInteractionEnabled = true
//        
//        containerView.addSubview(pdfView)
//        
//        // Container for canvas views
//        let canvasContainerView = UIView()
//        canvasContainerView.backgroundColor = .clear
//        canvasContainerView.isUserInteractionEnabled = false
//        canvasContainerView.clipsToBounds = true
//        canvasContainerView.translatesAutoresizingMaskIntoConstraints = false
//        containerView.addSubview(canvasContainerView)
//        
//        // Invisible overlay for text annotation taps
//        let textAnnotationOverlay = UIView()
//        textAnnotationOverlay.backgroundColor = .clear
//        textAnnotationOverlay.isUserInteractionEnabled = false
//        textAnnotationOverlay.translatesAutoresizingMaskIntoConstraints = false
//        containerView.addSubview(textAnnotationOverlay)
//        
//        NSLayoutConstraint.activate([
//            pdfView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//            pdfView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            pdfView.topAnchor.constraint(equalTo: containerView.topAnchor),
//            pdfView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
//            
//            canvasContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//            canvasContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            canvasContainerView.topAnchor.constraint(equalTo: containerView.topAnchor),
//            canvasContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
//            
//            textAnnotationOverlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//            textAnnotationOverlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            textAnnotationOverlay.topAnchor.constraint(equalTo: containerView.topAnchor),
//            textAnnotationOverlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
//        ])
//        
//        // Add tap gesture for text annotation
//        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTextAnnotationTap(_:)))
//        textAnnotationOverlay.addGestureRecognizer(tapGesture)
//        
//        context.coordinator.pdfView = pdfView
//        context.coordinator.canvasContainerView = canvasContainerView
//        context.coordinator.containerView = containerView
//        context.coordinator.textAnnotationOverlay = textAnnotationOverlay
//        context.coordinator.setup()
//        
//        return containerView
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {
//        context.coordinator.updateTool(selectedTool)
//        context.coordinator.goToPage(currentPage)
//        context.coordinator.updateZoom(zoomScale)
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(document: document, currentPage: $currentPage, zoomScale: $zoomScale)
//    }
//    
//    class Coordinator: NSObject, PKCanvasViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
//        let document: PDFDocument
//        var pdfView: PDFView?
//        var canvasContainerView: UIView?
//        var containerView: UIView?
//        var textAnnotationOverlay: UIView?
//        var canvasViews: [Int: PKCanvasView] = [:]
//        var doubleTapGestures: [Int: UITapGestureRecognizer] = [:]
//        var pageOriginalSizes: [Int: CGSize] = [:]
//        var currentTextField: UITextField?
//        var currentTextAnnotation: PDFAnnotation?
//        
//        @Binding var currentPage: Int
//        @Binding var zoomScale: CGFloat
//        
//        var displayLink: CADisplayLink?
//        var isTextAnnotationMode = false
//        
//        init(document: PDFDocument, currentPage: Binding<Int>, zoomScale: Binding<CGFloat>) {
//            self.document = document
//            self._currentPage = currentPage
//            self._zoomScale = zoomScale
//            super.init()
//        }
//        
//        func setup() {
//            guard let pdfView = pdfView else { return }
//            
//            // Store original page sizes
//            for pageIndex in 0..<document.pageCount {
//                if let page = document.page(at: pageIndex) {
//                    pageOriginalSizes[pageIndex] = page.bounds(for: .mediaBox).size
//                }
//            }
//            
//            NotificationCenter.default.addObserver(
//                self,
//                selector: #selector(pdfViewChanged),
//                name: .PDFViewPageChanged,
//                object: pdfView
//            )
//            
//            NotificationCenter.default.addObserver(
//                self,
//                selector: #selector(pdfViewChanged),
//                name: .PDFViewScaleChanged,
//                object: pdfView
//            )
//            
//            NotificationCenter.default.addObserver(
//                self,
//                selector: #selector(pdfViewChanged),
//                name: .PDFViewVisiblePagesChanged,
//                object: pdfView
//            )
//            
//            createCanvasViews()
//            updateCanvasFrames()
//            startDisplayLink()
//        }
//        
//        @objc func handleTextAnnotationTap(_ gesture: UITapGestureRecognizer) {
//            guard isTextAnnotationMode,
//                  let pdfView = pdfView,
//                  let containerView = containerView else { return }
//            
//            // Get tap location in container view
//            let tapLocation = gesture.location(in: containerView)
//            
//            // Find which page was tapped
//            var tappedPage: PDFPage?
//            var pageFrame: CGRect = .zero
//            
//            for pageIndex in 0..<document.pageCount {
//                if let page = pdfView.document?.page(at: pageIndex) {
//                    let frame = pdfView.convert(page.bounds(for: .mediaBox), from: page)
//                    if frame.contains(tapLocation) {
//                        tappedPage = page
//                        pageFrame = frame
//                        break
//                    }
//                }
//            }
//            
//            guard let page = tappedPage else { return }
//            
//            // Convert tap location to PDF page coordinates
//            let locationInPDFView = containerView.convert(tapLocation, to: pdfView)
//            let locationInPage = pdfView.convert(locationInPDFView, to: page)
//            
//            // Show text input at tap location
//            showTextInput(at: tapLocation, page: page, pageLocation: locationInPage)
//        }
//        
//        func showTextInput(at screenLocation: CGPoint, page: PDFPage, pageLocation: CGPoint) {
//            // Create text field for input
//            let textField = UITextField()
//            textField.frame = CGRect(x: screenLocation.x, y: screenLocation.y, width: 200, height: 40)
//            textField.backgroundColor = UIColor.yellow.withAlphaComponent(0.9)
//            textField.borderStyle = .roundedRect
//            textField.placeholder = "Enter text..."
//            textField.delegate = self
//            textField.autocorrectionType = .no
//            
//            // Store reference
//            currentTextField = textField
//            
//            // Add to container
//            containerView?.addSubview(textField)
//            textField.becomeFirstResponder()
//            
//            // Store the page and location for when text is entered
//            textField.tag = document.index(for: page)
//            textField.accessibilityHint = "\(pageLocation.x),\(pageLocation.y)"
//        }
//        
//        // UITextFieldDelegate
//        func textFieldDidEndEditing(_ textField: UITextField) {
//            guard let text = textField.text, !text.isEmpty else {
//                textField.removeFromSuperview()
//                currentTextField = nil
//                return
//            }
//            
//            // Get stored location
//            let pageIndex = textField.tag
//            guard let page = document.page(at: pageIndex),
//                  let locationString = textField.accessibilityHint,
//                  let pdfView = pdfView else {
//                textField.removeFromSuperview()
//                currentTextField = nil
//                return
//            }
//            
//            // Parse location
//            let coords = locationString.split(separator: ",")
//            guard coords.count == 2,
//                  let x = Double(coords[0]),
//                  let y = Double(coords[1]) else {
//                textField.removeFromSuperview()
//                currentTextField = nil
//                return
//            }
//            
//            // Create text annotation at the tapped location
//            let textSize = (text as NSString).size(withAttributes: [
//                .font: UIFont.systemFont(ofSize: 14)
//            ])
//            
//            let bounds = CGRect(
//                x: x - 5,
//                y: y - textSize.height - 5,
//                width: textSize.width + 10,
//                height: textSize.height + 10
//            )
//            
//            let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
//            annotation.contents = text
//            annotation.backgroundColor = UIColor.yellow.withAlphaComponent(0.3)
//            annotation.color = .black
//            annotation.font = UIFont.systemFont(ofSize: 14)
//            
//            page.addAnnotation(annotation)
//            
//            // Clean up
//            textField.removeFromSuperview()
//            currentTextField = nil
//        }
//        
//        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//            textField.resignFirstResponder()
//            return true
//        }
//        
//        func startDisplayLink() {
//            displayLink = CADisplayLink(target: self, selector: #selector(updateCanvasFrames))
//            displayLink?.add(to: .main, forMode: .common)
//        }
//        
//        func stopDisplayLink() {
//            displayLink?.invalidate()
//            displayLink = nil
//        }
//        
//        func createCanvasViews() {
//            guard let document = pdfView?.document else { return }
//            
//            for pageIndex in 0..<document.pageCount {
//                guard let originalSize = pageOriginalSizes[pageIndex] else { continue }
//                
//                let canvasView = PKCanvasView()
//                canvasView.backgroundColor = .clear
//                canvasView.isOpaque = false
//                canvasView.drawingPolicy = .anyInput
//                canvasView.tool = PKInkingTool(.pencil, color: .black, width: 2)
//                canvasView.delegate = self
//                canvasView.isUserInteractionEnabled = false
//                
//                // Set canvas bounds to original PDF page size
//                canvasView.bounds = CGRect(origin: .zero, size: originalSize)
//                
//                let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
//                doubleTap.numberOfTapsRequired = 2
//                doubleTap.delegate = self
//                canvasView.addGestureRecognizer(doubleTap)
//                doubleTapGestures[pageIndex] = doubleTap
//                
//                canvasContainerView?.addSubview(canvasView)
//                canvasViews[pageIndex] = canvasView
//            }
//        }
//        
//        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
//            enableScrollMode()
//            
//            if let canvasView = gesture.view as? PKCanvasView {
//                UIView.animate(withDuration: 0.2) {
//                    canvasView.alpha = 0.5
//                } completion: { _ in
//                    UIView.animate(withDuration: 0.2) {
//                        canvasView.alpha = 1.0
//                    }
//                }
//            }
//        }
//        
//        @objc func pdfViewChanged() {
//            updateCanvasFrames()
//            
//            if let pdfView = pdfView, let currentPDFPage = pdfView.currentPage,
//               let pageIndex = pdfView.document?.index(for: currentPDFPage) {
//                DispatchQueue.main.async {
//                    self.currentPage = pageIndex
//                }
//            }
//            
//            if let pdfView = pdfView {
//                DispatchQueue.main.async {
//                    self.zoomScale = pdfView.scaleFactor
//                }
//            }
//        }
//        
//        @objc func updateCanvasFrames() {
//            guard let pdfView = pdfView, let containerView = containerView else { return }
//            
//            let visibleBounds = containerView.bounds
//            
//            for (pageIndex, canvasView) in canvasViews {
//                guard let page = pdfView.document?.page(at: pageIndex),
//                      let originalSize = pageOriginalSizes[pageIndex] else { continue }
//                
//                // Get the displayed (scaled) page frame
//                let displayedPageFrame = pdfView.convert(page.bounds(for: .mediaBox), from: page)
//                
//                // Check visibility
//                let isPageVisible = visibleBounds.intersects(displayedPageFrame)
//                
//                if !isPageVisible {
//                    canvasView.isHidden = true
//                } else {
//                    canvasView.isHidden = false
//                    
//                    // Calculate scale factor
//                    let scaleX = displayedPageFrame.width / originalSize.width
//                    let scaleY = displayedPageFrame.height / originalSize.height
//                    
//                    // Position canvas center at page center
//                    canvasView.center = CGPoint(
//                        x: displayedPageFrame.midX,
//                        y: displayedPageFrame.midY
//                    )
//                    
//                    // Apply scale transform
//                    let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
//                    canvasView.transform = transform
//                }
//            }
//        }
//        
//        func goToPage(_ pageIndex: Int) {
//            guard let pdfView = pdfView,
//                  let page = pdfView.document?.page(at: pageIndex) else { return }
//            pdfView.go(to: page)
//        }
//        
//        func updateZoom(_ scale: CGFloat) {
//            guard let pdfView = pdfView else { return }
//            
//            if abs(pdfView.scaleFactor - scale) > 0.01 {
//                pdfView.scaleFactor = scale
//            }
//        }
//        
//        func enableScrollMode() {
//            pdfView?.isUserInteractionEnabled = true
//            canvasContainerView?.isUserInteractionEnabled = false
//            textAnnotationOverlay?.isUserInteractionEnabled = false
//            canvasViews.values.forEach { $0.isUserInteractionEnabled = false }
//            isTextAnnotationMode = false
//        }
//        
//        func updateTool(_ tool: AnnotationTool_PencilKit) {
//            guard let pdfView = pdfView else { return }
//            
//            switch tool {
//            case .hand:
//                enableScrollMode()
//                
//            case .pencil:
//                enableDrawing()
//                setToolForAllCanvases(PKInkingTool(.pencil, color: .black, width: 2))
//                
//            case .pen:
//                enableDrawing()
//                setToolForAllCanvases(PKInkingTool(.pen, color: .blue, width: 3))
//                
//            case .eraser:
//                enableDrawing()
//                setToolForAllCanvases(PKEraserTool(.vector))
//                
//            case .text:
//                enableTextAnnotation()
//                
//            case .highlight:
//                disableDrawing()
//                addHighlightAnnotation(to: pdfView)
//                
//            case .shape:
//                disableDrawing()
//                addShapeAnnotation(to: pdfView)
//                
//            case .comment:
//                disableDrawing()
//                addCommentAnnotation(to: pdfView)
//            }
//        }
//        
//        func enableTextAnnotation() {
//            pdfView?.isUserInteractionEnabled = false
//            canvasContainerView?.isUserInteractionEnabled = false
//            textAnnotationOverlay?.isUserInteractionEnabled = true
//            canvasViews.values.forEach { $0.isUserInteractionEnabled = false }
//            isTextAnnotationMode = true
//        }
//        
//        func enableDrawing() {
//            pdfView?.isUserInteractionEnabled = false
//            canvasContainerView?.isUserInteractionEnabled = true
//            textAnnotationOverlay?.isUserInteractionEnabled = false
//            canvasViews.values.forEach { $0.isUserInteractionEnabled = true }
//            isTextAnnotationMode = false
//        }
//        
//        func disableDrawing() {
//            pdfView?.isUserInteractionEnabled = true
//            canvasContainerView?.isUserInteractionEnabled = false
//            textAnnotationOverlay?.isUserInteractionEnabled = false
//            canvasViews.values.forEach { $0.isUserInteractionEnabled = false }
//            isTextAnnotationMode = false
//        }
//        
//        func setToolForAllCanvases(_ tool: PKTool) {
//            canvasViews.values.forEach { $0.tool = tool }
//        }
//        
//        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//            return true
//        }
//        
//        func addHighlightAnnotation(to pdfView: PDFView) {
//            guard let page = pdfView.currentPage,
//                  let selection = pdfView.currentSelection else { return }
//            
//            let selections = selection.selectionsByLine()
//            for selection in selections {
//                let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
//                highlight.color = UIColor.yellow.withAlphaComponent(0.5)
//                page.addAnnotation(highlight)
//            }
//        }
//        
//        func addShapeAnnotation(to pdfView: PDFView) {
//            guard let page = pdfView.currentPage else { return }
//            
//            let bounds = CGRect(x: 100, y: 200, width: 150, height: 100)
//            let annotation = PDFAnnotation(bounds: bounds, forType: .square, withProperties: nil)
//            annotation.color = .red
//            annotation.interiorColor = UIColor.red.withAlphaComponent(0.2)
//            
//            page.addAnnotation(annotation)
//        }
//        
//        func addCommentAnnotation(to pdfView: PDFView) {
//            guard let page = pdfView.currentPage else { return }
//            
//            let bounds = CGRect(x: 100, y: 300, width: 20, height: 20)
//            let annotation = PDFAnnotation(bounds: bounds, forType: .text, withProperties: nil)
//            annotation.contents = "This is a comment"
//            annotation.color = .yellow
//            
//            page.addAnnotation(annotation)
//        }
//        
//        deinit {
//            NotificationCenter.default.removeObserver(self)
//            stopDisplayLink()
//        }
//    }
//}
//
//// MARK: - Usage Example
//struct PencilKitAnnotation: View {
//    var body: some View {
//        if let url = Bundle.main.url(forResource: "sample1", withExtension: "pdf"),
//           let document = PDFDocument(url: url) {
//            PDFAnnotationView(pdfDocument: document)
//        } else {
//            Text("PDF not found")
//        }
//    }
//}
